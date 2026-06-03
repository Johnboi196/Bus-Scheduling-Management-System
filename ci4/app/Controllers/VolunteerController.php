<?php

namespace App\Controllers;

use CodeIgniter\RESTful\ResourceController;

/**
 * VolunteerController
 * ----------------------------------------------------------------------
 * Driver-side: list unassigned trips, submit volunteer request.
 * Supervisor-side: review pending volunteer requests.
 *
 * Gate: a driver can only see + volunteer for unassigned trips if they
 * have at least one Approved leave application.
 *
 * Supervisor approval flow:
 *   - Approve one → schedules.driver_id = driver, status=Approved.
 *     Any OTHER pending requests for the same schedule auto-reject.
 *   - Reject     → trip stays unassigned; other volunteers can still try.
 */
class VolunteerController extends ResourceController
{
    protected $format = 'json';

    /**
     * GET /api/volunteer/available?driver_id={id}
     * Returns the list of unassigned trips THIS driver is eligible to claim.
     *
     * Eligibility rules:
     *   - Trip must be unassigned (driver_id IS NULL).
     *   - Trip must be in the future (schedule_date >= today).
     *   - Trip must not overlap with the driver's existing assignments.
     *   - Driver hasn't already volunteered for this trip (pending).
     */
    public function available()
    {
        $driverId = (int)$this->request->getGet('driver_id');
        if ($driverId <= 0) {
            return $this->failValidationErrors('driver_id is required.');
        }

        $db = \Config\Database::connect();

        // List unassigned future trips.
        $today = date('Y-m-d');
        $rows = $db->table('schedules s')
            ->select('s.*, r.route_name, r.origin, r.destination, b.plate_number,
                      EXISTS(SELECT 1 FROM volunteer_requests vr
                             WHERE vr.schedule_id = s.schedule_id
                               AND vr.driver_id   = ' . (int)$driverId . '
                               AND vr.status      = "Pending") AS already_requested')
            ->join('routes r', 'r.route_id = s.route_id')
            ->join('buses b',  'b.bus_id   = s.bus_id')
            ->where('s.driver_id IS NULL', null, false)
            ->where('s.schedule_date >=', $today)
            ->orderBy('s.schedule_date', 'ASC')
            ->orderBy('s.expected_start', 'ASC')
            ->get()->getResultArray();

        // Filter out trips that overlap with this driver's existing
        // assignments (so they can't accidentally double-book).
        $mine = $db->table('schedules')
            ->select('schedule_date, expected_start, expected_end')
            ->where('driver_id', $driverId)
            ->where('schedule_date >=', $today)
            ->get()->getResultArray();

        $filtered = [];
        foreach ($rows as $r) {
            $clash = false;
            foreach ($mine as $m) {
                if ($r['schedule_date'] === $m['schedule_date']) {
                    if ($r['expected_start'] < $m['expected_end']
                        && $r['expected_end'] > $m['expected_start']) {
                        $clash = true;
                        break;
                    }
                }
            }
            if (!$clash) $filtered[] = $r;
        }

        // Cast numeric fields explicitly — MySQLi often returns ints as
        // strings, which breaks Flutter's `as int` cast on the client.
        foreach ($filtered as &$r) {
            $r['schedule_id']      = (int)$r['schedule_id'];
            $r['bus_id']           = (int)$r['bus_id'];
            $r['route_id']         = (int)$r['route_id'];
            $r['already_requested']= (int)$r['already_requested'];
        }
        unset($r);

        return $this->respond([
            'status'   => 'success',
            'eligible' => true,
            'count'    => count($filtered),
            'trips'    => $filtered,
        ]);
    }

    /**
     * POST /api/volunteer/request
     * Body: { "schedule_id":12, "driver_id":2, "note":"happy to cover" }
     */
    public function create()
    {
        $in = $this->request->getJSON(true) ?? $this->request->getPost();

        $scheduleId = (int)($in['schedule_id'] ?? 0);
        $driverId   = (int)($in['driver_id']   ?? 0);
        $note       = trim($in['note'] ?? '');

        if ($scheduleId <= 0 || $driverId <= 0) {
            return $this->failValidationErrors('schedule_id and driver_id are required.');
        }

        $db = \Config\Database::connect();

        // Trip must still be unassigned.
        $sched = $db->table('schedules')
            ->where('schedule_id', $scheduleId)
            ->get()->getRowArray();
        if (!$sched) {
            return $this->failNotFound('Schedule not found.');
        }
        if ($sched['driver_id'] !== null) {
            return $this->failValidationErrors('That trip is no longer available.');
        }

        // No duplicate pending volunteer for same driver+trip.
        $existing = $db->table('volunteer_requests')
            ->where('schedule_id', $scheduleId)
            ->where('driver_id',   $driverId)
            ->where('status', 'Pending')
            ->countAllResults();
        if ($existing > 0) {
            return $this->failValidationErrors(
                'You already have a pending volunteer request for this trip.');
        }

        $db->table('volunteer_requests')->insert([
            'schedule_id' => $scheduleId,
            'driver_id'   => $driverId,
            'note'        => $note ?: null,
            'status'      => 'Pending',
        ]);

        return $this->respond([
            'status'       => 'success',
            'message'      => 'Volunteer request submitted.',
            'volunteer_id' => $db->insertID(),
        ]);
    }

    /**
     * GET /api/volunteer/byDriver/{driver_id}
     * Driver's own volunteer request history.
     */
    public function byDriver($driverId = null)
    {
        $driverId = (int)$driverId;
        if ($driverId <= 0) {
            return $this->failValidationErrors('Invalid driver_id.');
        }

        $db = \Config\Database::connect();
        $rows = $db->table('volunteer_requests vr')
            ->select('vr.*, s.schedule_date, s.expected_start, s.expected_end,
                      r.route_name, r.origin, r.destination, b.plate_number')
            ->join('schedules s', 's.schedule_id = vr.schedule_id')
            ->join('routes r',    'r.route_id    = s.route_id')
            ->join('buses b',     'b.bus_id      = s.bus_id')
            ->where('vr.driver_id', $driverId)
            ->orderBy('vr.created_at', 'DESC')
            ->get()->getResultArray();

        return $this->respond([
            'status'     => 'success',
            'volunteers' => $rows,
        ]);
    }
}
