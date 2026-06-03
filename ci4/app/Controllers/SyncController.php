<?php

namespace App\Controllers;

use CodeIgniter\RESTful\ResourceController;

/**
 * SyncController
 * ----------------------------------------------------------------------
 * Maps to Sequence Diagram step 5 "Background Offline Syncing":
 *   LOOP [Every 5 minutes / On Connection Restored]
 *     pushCacheData(tripDataList)
 *     UPDATE schedules SET actual_start, actual_end, is_synced = 1
 *
 * The Flutter app pushes a JSON array of all records it captured while
 * the bus was offline. We process them inside a transaction so the
 * device only clears its local cache after a confirmed success.
 */
class SyncController extends ResourceController
{
    protected $format = 'json';

    /**
     * POST /api/sync/push
     * Body (JSON):
     * {
     *   "trips": [
     *     { "schedule_id": 12, "actual_start": "2026-05-11 08:03:21",
     *       "actual_end": "2026-05-11 10:11:02", "job_status": "Completed" },
     *     { "schedule_id": 13, "actual_start": "2026-05-11 11:00:00",
     *       "actual_end": null, "job_status": "In-Progress" }
     *   ]
     * }
     */
    public function syncCachedData()
    {
        $payload = $this->request->getJSON(true);
        if (!isset($payload['trips']) || !is_array($payload['trips'])) {
            return $this->failValidationErrors('Missing "trips" array.');
        }

        $trips = $payload['trips'];
        if (count($trips) === 0) {
            return $this->respond([
                'status'  => 'success',
                'message' => 'Nothing to sync.',
                'updated' => 0,
            ]);
        }

        $db = \Config\Database::connect();
        $db->transStart();

        $updated = 0;
        $skipped = [];

        foreach ($trips as $i => $trip) {
            $sid = (int)($trip['schedule_id'] ?? 0);
            if ($sid <= 0) { $skipped[] = $i; continue; }

            $update = [
                'is_synced' => 1,
            ];
            // Only set columns the device actually provided.
            if (array_key_exists('actual_start', $trip) && $trip['actual_start'] !== null) {
                $update['actual_start'] = $trip['actual_start'];
            }
            if (array_key_exists('actual_end', $trip) && $trip['actual_end'] !== null) {
                $update['actual_end'] = $trip['actual_end'];
            }
            if (!empty($trip['job_status'])) {
                $allowed = ['Pending','In-Progress','Completed','Cancelled'];
                if (in_array($trip['job_status'], $allowed, true)) {
                    $update['job_status'] = $trip['job_status'];
                }
            }

            $db->table('schedules')
               ->where('schedule_id', $sid)
               ->update($update);

            $updated++;
        }

        $db->transComplete();

        if ($db->transStatus() === false) {
            log_message('error', 'Sync transaction failed.');
            return $this->failServerError('Sync transaction failed.');
        }

        log_message('info', "Sync OK: {$updated} schedules updated.");

        // The "confirm update" -> "return syncSuccess" of the sequence diagram.
        // Only after seeing this success does the Flutter app clear its cache.
        return $this->respond([
            'status'  => 'success',
            'message' => 'Sync completed.',
            'updated' => $updated,
            'skipped' => $skipped,
        ]);
    }
}
