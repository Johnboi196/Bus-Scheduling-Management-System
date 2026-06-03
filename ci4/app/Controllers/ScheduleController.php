<?php

namespace App\Controllers;

use CodeIgniter\RESTful\ResourceController;

/**
 * ScheduleController
 * ----------------------------------------------------------------------
 * Maps to Sequence Diagram step 3: "Hardware Identification & Schedule Download".
 *
 * The in-bus Flutter device boots, reads its own MAC address, and calls:
 *   GET /api/schedule/byMac/AA:BB:CC:DD:EE:01
 *
 * We JOIN buses -> schedules -> drivers/routes and return today's itinerary
 * as JSON. The device caches the result in SQLite for offline use.
 */
class ScheduleController extends ResourceController
{
    protected $format = 'json';

    /**
     * GET /api/schedule/byMac/{mac}?driver_id={id}
     * Returns schedules assigned to the bus with this MAC for TODAY.
     * If driver_id is provided, additionally filters to that driver only —
     * so when a different driver logs in to the same bus tablet, they only
     * see their own trips.
     */
    public function fetchByMac($mac = null)
    {
        if (!$mac) {
            return $this->failValidationErrors('MAC address is required.');
        }

        // Optional driver filter (sent as query string).
        $driverId = $this->request->getGet('driver_id');
        $driverId = $driverId !== null ? (int)$driverId : null;

        // Normalise to upper-case so "aa:bb:..." and "AA:BB:..." both work.
        $mac = strtoupper(trim($mac));

        $db = \Config\Database::connect();

        // Build the query. Filter by bus MAC and today's date.
        $builder = $db->table('schedules s')
            ->select('
                s.schedule_id,
                s.driver_id,
                s.schedule_date,
                s.expected_start,
                s.expected_end,
                s.actual_start,
                s.actual_end,
                s.job_status,
                s.is_synced,
                b.bus_id,
                b.plate_number,
                b.mac_address,
                d.full_name AS driver_name,
                r.route_id,
                r.route_name,
                r.origin,
                r.destination
            ')
            ->join('buses b',   'b.bus_id   = s.bus_id')
            ->join('drivers d', 'd.driver_id = s.driver_id')
            ->join('routes r',  'r.route_id  = s.route_id')
            ->where('b.mac_address', $mac)
            ->where('s.schedule_date', date('Y-m-d'));

        // The shift-change gate: if driver_id is sent, only return their trips.
        if ($driverId !== null && $driverId > 0) {
            $builder->where('s.driver_id', $driverId);
        }

        $rows = $builder->orderBy('s.expected_start', 'ASC')
                        ->get()
                        ->getResultArray();

        if (empty($rows)) {
            return $this->respond([
                'status'   => 'success',
                'message'  => 'No schedules found for this bus today.',
                'mac'      => $mac,
                'schedules'=> [],
            ]);
        }

        return $this->respond([
            'status'    => 'success',
            'mac'       => $mac,
            'count'     => count($rows),
            'schedules' => $rows,
        ]);
    }

    /**
     * GET /api/schedule/byDriver/{driver_id}
     * Returns the driver's own schedule list (used by the mobile UI screen,
     * Sequence Diagram step 2 "View Assigned Schedules").
     */
    public function fetchByDriver($driverId = null)
    {
        if (!$driverId) {
            return $this->failValidationErrors('Driver ID is required.');
        }

        $db = \Config\Database::connect();
        $rows = $db->table('schedules s')
            ->select('s.*, r.route_name, r.origin, r.destination, b.plate_number')
            ->join('routes r', 'r.route_id = s.route_id')
            ->join('buses b',  'b.bus_id   = s.bus_id')
            ->where('s.driver_id', (int)$driverId)
            ->where('s.schedule_date >=', date('Y-m-d'))
            ->orderBy('s.schedule_date', 'ASC')
            ->orderBy('s.expected_start', 'ASC')
            ->get()
            ->getResultArray();

        return $this->respond([
            'status'    => 'success',
            'count'     => count($rows),
            'schedules' => $rows,
        ]);
    }

    /**
     * POST /api/schedule/updateStatus
     * Body: { "schedule_id":1, "actual_start":"2026-05-11 08:03:21",
     *         "actual_end":null, "job_status":"In-Progress" }
     *
     * Used for the ONLINE path of the Start/End buttons
     * (Sequence Diagram step 4 "[Connected]" branch).
     */
    public function updateStatus()
    {
        $input = $this->request->getJSON(true) ?? $this->request->getPost();

        $scheduleId  = (int)($input['schedule_id'] ?? 0);
        $jobStatus   = $input['job_status']   ?? null;
        $actualStart = $input['actual_start'] ?? null;
        $actualEnd   = $input['actual_end']   ?? null;

        if ($scheduleId <= 0) {
            return $this->failValidationErrors('schedule_id is required.');
        }

        $allowed = ['Pending','In-Progress','Completed','Cancelled'];
        if ($jobStatus !== null && !in_array($jobStatus, $allowed, true)) {
            return $this->failValidationErrors('Invalid job_status.');
        }

        $data = ['is_synced' => 1];     // came from server path = already in sync
        if ($jobStatus  !== null) $data['job_status']   = $jobStatus;
        if ($actualStart!== null) $data['actual_start'] = $actualStart;
        if ($actualEnd  !== null) $data['actual_end']   = $actualEnd;

        $db = \Config\Database::connect();
        $db->table('schedules')->where('schedule_id', $scheduleId)->update($data);

        if ($db->affectedRows() === 0) {
            return $this->failNotFound('Schedule not found or no change.');
        }

        return $this->respond([
            'status'      => 'success',
            'message'     => 'Schedule updated.',
            'schedule_id' => $scheduleId,
        ]);
    }

    
    public function history($driverId = null)
{
    $driverId = (int)$driverId;
    if ($driverId <= 0) {
        return $this->failValidationErrors('Invalid driver_id.');
    }

    $db = \Config\Database::connect();

    $rows = $db->table('schedules s')
        ->select('
            s.schedule_id,
            s.schedule_date,
            s.expected_start,
            s.expected_end,
            s.actual_start,
            s.actual_end,
            s.job_status,
            r.route_name,
            r.origin,
            r.destination,
            b.plate_number,
            TIMESTAMPDIFF(SECOND, s.actual_start, s.actual_end) AS duration_seconds
        ')
        ->join('routes r', 'r.route_id = s.route_id')
        ->join('buses b',  'b.bus_id   = s.bus_id')
        ->where('s.driver_id', $driverId)
        ->where('s.job_status', 'Completed')
        ->where('s.actual_start IS NOT NULL', null, false)
        ->where('s.actual_end IS NOT NULL',   null, false)
        ->orderBy('s.schedule_date', 'DESC')
        ->orderBy('s.actual_start', 'DESC')
        ->get()->getResultArray();

    // Cast numeric fields explicitly — MySQLi often returns them
    // as strings which breaks Flutter's type cast.
    $totalSeconds = 0;
    foreach ($rows as &$r) {
        $r['schedule_id']      = (int)$r['schedule_id'];
        $r['duration_seconds'] = (int)$r['duration_seconds'];
        $totalSeconds         += $r['duration_seconds'];
    }
    unset($r);  // break the reference

    return $this->respond([
        'status'        => 'success',
        'count'         => count($rows),
        'total_seconds' => $totalSeconds,
        'trips'         => $rows,
    ]);
}
}
