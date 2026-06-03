<?php

namespace App\Models;

use CodeIgniter\Model;

class ScheduleModel extends Model
{
    protected $table         = 'schedules';
    protected $primaryKey    = 'schedule_id';
    protected $useAutoIncrement = true;
    protected $returnType    = 'array';
    protected $useTimestamps = true;
    protected $createdField  = 'created_at';
    protected $updatedField  = 'updated_at';

    protected $allowedFields = [
        'driver_id','supervisor_id','bus_id','route_id',
        'schedule_date','expected_start','expected_end',
        'actual_start','actual_end','job_status','is_synced','notes',
    ];

    /** Used by ScheduleController::fetchByMac */
    public function getTodayByMac(string $mac): array
    {
        return $this->db->table($this->table . ' s')
            ->select('s.*, b.plate_number, b.mac_address, d.full_name AS driver_name,
                      r.route_name, r.origin, r.destination')
            ->join('buses b',   'b.bus_id   = s.bus_id')
            ->join('drivers d', 'd.driver_id = s.driver_id')
            ->join('routes r',  'r.route_id  = s.route_id')
            ->where('b.mac_address', strtoupper($mac))
            ->where('s.schedule_date', date('Y-m-d'))
            ->orderBy('s.expected_start')
            ->get()->getResultArray();
    }
}
