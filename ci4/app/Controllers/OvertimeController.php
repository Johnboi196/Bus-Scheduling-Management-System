<?php

namespace App\Controllers;

use CodeIgniter\RESTful\ResourceController;

/**
 * OvertimeController
 * Use Case Diagram: "Request for Overtime" (driver) +
 *                   "Approve or reject overtime request" (supervisor).
 * Activity Diagram: triggered when "Trip Delayed/Late?" is YES.
 */
class OvertimeController extends ResourceController
{
    protected $format = 'json';

    /**
     * POST /api/overtime/request
     * Body: { "schedule_id":1, "extra_minutes":20, "reason":"Traffic jam" }
     */
    public function create()
    {
        $in = $this->request->getJSON(true) ?? $this->request->getPost();
        $sid = (int)($in['schedule_id'] ?? 0);
        $mins= (int)($in['extra_minutes'] ?? 0);
        $reason = trim($in['reason'] ?? '');

        if ($sid <= 0 || $mins <= 0) {
            return $this->failValidationErrors('schedule_id and extra_minutes are required.');
        }

        $db = \Config\Database::connect();
        $db->table('overtime_requests')->insert([
            'schedule_id'   => $sid,
            'extra_minutes' => $mins,
            'reason'        => $reason ?: null,
            'status'        => 'Pending',
        ]);

        return $this->respond([
            'status'      => 'success',
            'message'     => 'Overtime request submitted.',
            'overtime_id' => $db->insertID(),
        ]);
    }

    /**
     * POST /api/overtime/review
     * Body: { "overtime_id":1, "supervisor_id":1, "decision":"Approved|Rejected" }
     */
    public function review()
    {
        $in = $this->request->getJSON(true) ?? $this->request->getPost();
        $id   = (int)($in['overtime_id']   ?? 0);
        $supv = (int)($in['supervisor_id'] ?? 0);
        $decision = $in['decision'] ?? '';

        if ($id <= 0 || !in_array($decision, ['Approved','Rejected'], true)) {
            return $this->failValidationErrors('Invalid overtime_id or decision.');
        }

        $db = \Config\Database::connect();
        $db->table('overtime_requests')
           ->where('overtime_id', $id)
           ->update([
               'status'        => $decision,
               'supervisor_id' => $supv ?: null,
               'reviewed_at'   => date('Y-m-d H:i:s'),
           ]);

        return $this->respond(['status'=>'success','message'=>"Overtime {$decision}."]);
    }
}
