<?php

namespace App\Controllers;

use CodeIgniter\RESTful\ResourceController;

/**
 * LeaveController
 * Use Case Diagram: "Manage leave applications" / "Review Leave Applications".
 *
 * Two endpoints:
 *   POST /api/leave/apply           - driver submits a new application
 *   GET  /api/leave/byDriver/{id}   - driver fetches their history
 */
class LeaveController extends ResourceController
{
    protected $format = 'json';

    /**
     * POST /api/leave/apply
     * Body: { "driver_id":1, "start_date":"2026-06-01",
     *         "end_date":"2026-06-03", "reason":"..." }
     */
    public function apply()
    {
        $in = $this->request->getJSON(true) ?? $this->request->getPost();

        $driverId = (int)($in['driver_id'] ?? 0);
        $start    = $in['start_date'] ?? '';
        $end      = $in['end_date']   ?? '';
        $reason   = trim($in['reason'] ?? '');

        if ($driverId <= 0 || $start === '' || $end === '') {
            return $this->failValidationErrors('driver_id, start_date, end_date are required.');
        }
        if (strtotime($end) < strtotime($start)) {
            return $this->failValidationErrors('end_date cannot be before start_date.');
        }

        $db = \Config\Database::connect();
        $db->table('leave_applications')->insert([
            'driver_id'  => $driverId,
            'start_date' => $start,
            'end_date'   => $end,
            'reason'     => $reason ?: null,
            'status'     => 'Pending',
        ]);

        return $this->respond([
            'status'   => 'success',
            'message'  => 'Leave application submitted.',
            'leave_id' => $db->insertID(),
        ]);
    }

    /**
     * GET /api/leave/byDriver/{driver_id}
     * Returns leave application history for one driver, newest first.
     */
    public function byDriver($driverId = null)
    {
        $driverId = (int)$driverId;
        if ($driverId <= 0) {
            return $this->failValidationErrors('Invalid driver_id.');
        }

        $db = \Config\Database::connect();
        $rows = $db->table('leave_applications')
            ->where('driver_id', $driverId)
            ->orderBy('created_at', 'DESC')
            ->get()
            ->getResultArray();

        return $this->respond([
            'status' => 'success',
            'count'  => count($rows),
            'leaves' => $rows,
        ]);
    }
}
