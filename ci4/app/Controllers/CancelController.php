<?php

namespace App\Controllers;

use CodeIgniter\RESTful\ResourceController;

/**
 * CancelController
 * ----------------------------------------------------------------------
 * Driver-side: submit a request to cancel a trip.
 * Supervisor-side: list pending, approve/reject.
 *
 * Workflow:
 *   1. Driver POST /api/cancel/request {schedule_id, driver_id, reason}
 *      → row added, status=Pending. Trip stays assigned.
 *   2. Supervisor reviews via web dashboard:
 *      Approved → schedules.driver_id = NULL (trip enters unassigned pool)
 *      Rejected → trip stays with original driver
 */
class CancelController extends ResourceController
{
    protected $format = 'json';

    /**
     * POST /api/cancel/request
     * Body: { "schedule_id":1, "driver_id":1, "reason":"Family emergency" }
     */
    public function create()
    {
        $in = $this->request->getJSON(true) ?? $this->request->getPost();

        $scheduleId = (int)($in['schedule_id'] ?? 0);
        $driverId   = (int)($in['driver_id']   ?? 0);
        $reason     = trim($in['reason'] ?? '');

        if ($scheduleId <= 0 || $driverId <= 0) {
            return $this->failValidationErrors('schedule_id and driver_id are required.');
        }

        $db = \Config\Database::connect();

        // Verify the trip exists and is actually assigned to this driver.
        $sched = $db->table('schedules')
            ->where('schedule_id', $scheduleId)
            ->where('driver_id',   $driverId)
            ->get()->getRowArray();
        if (!$sched) {
            return $this->failNotFound('Schedule not found or not assigned to you.');
        }

        // Reject duplicate pending requests on the same trip by the same driver.
        $existing = $db->table('cancel_requests')
            ->where('schedule_id', $scheduleId)
            ->where('driver_id',   $driverId)
            ->where('status', 'Pending')
            ->countAllResults();
        if ($existing > 0) {
            return $this->failValidationErrors(
                'You already have a pending cancellation for this trip.');
        }

        // Don't allow cancelling a completed/in-progress trip.
        if (in_array($sched['job_status'], ['Completed','In-Progress'], true)) {
            return $this->failValidationErrors(
                'Cannot cancel a trip that has already started.');
        }

        $db->table('cancel_requests')->insert([
            'schedule_id' => $scheduleId,
            'driver_id'   => $driverId,
            'reason'      => $reason ?: null,
            'status'      => 'Pending',
        ]);

        return $this->respond([
            'status'    => 'success',
            'message'   => 'Cancellation request submitted.',
            'cancel_id' => $db->insertID(),
        ]);
    }

    /**
     * GET /api/cancel/byDriver/{driver_id}
     * Driver's own cancellation history for showing badges in the app.
     */
    public function byDriver($driverId = null)
    {
        $driverId = (int)$driverId;
        if ($driverId <= 0) {
            return $this->failValidationErrors('Invalid driver_id.');
        }

        $db = \Config\Database::connect();
        $rows = $db->table('cancel_requests cr')
            ->select('cr.*, s.schedule_date, s.expected_start, s.expected_end,
                      r.route_name, b.plate_number')
            ->join('schedules s', 's.schedule_id = cr.schedule_id')
            ->join('routes r',    'r.route_id    = s.route_id')
            ->join('buses b',     'b.bus_id      = s.bus_id')
            ->where('cr.driver_id', $driverId)
            ->orderBy('cr.created_at', 'DESC')
            ->get()->getResultArray();

        return $this->respond([
            'status'  => 'success',
            'cancels' => $rows,
        ]);
    }
}
