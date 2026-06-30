<?php

namespace App\Controllers\Web;

use CodeIgniter\Controller;

/**
 * SupervisorController
 * --------------------------------------------------------------------
 * Handles the supervisor dashboard pages. Maps to Use Case Diagram:
 *   - Create Schedule / Edit / Delete
 *   - Review Overtime Requests
 *   - Review Leave Applications
 *   - View live fleet (Monitor Job Status)
 */
class SupervisorController extends Controller
{
    /** Convenience: render a page with the shared layout. */
    private function render(string $title, string $contentView, array $data = [])
    {
        $data['title']    = $title;
        $data['role']     = 'supervisor';
        $data['userName'] = session('user_name');
        $data['content']  = view($contentView, $data);
        return view('layouts/main', $data);
    }

    /**
     * Check whether a driver has an APPROVED leave that covers a given date.
     * Returns true if the driver is unavailable, false otherwise.
     */
    private function driverOnLeave(int $driverId, string $date): bool
    {
        if ($driverId <= 0 || empty($date)) {
            return false;
        }
        $db = \Config\Database::connect();
        $count = $db->table('leave_applications')
            ->where('driver_id', $driverId)
            ->where('status', 'Approved')
            ->where('start_date <=', $date)
            ->where('end_date >=', $date)
            ->countAllResults();
        return $count > 0;
    }

    // ------------------------------------------------------------------
    // DASHBOARD — KPI cards
    // ------------------------------------------------------------------
    public function dashboard()
    {
        $db = \Config\Database::connect();
        $today = date('Y-m-d');

        $stats = [
            'today_total'    => $db->table('schedules')->where('schedule_date',$today)->countAllResults(),
            'in_progress'    => $db->table('schedules')->where('schedule_date',$today)
                                   ->where('job_status','In-Progress')->countAllResults(),
            'completed'      => $db->table('schedules')->where('schedule_date',$today)
                                   ->where('job_status','Completed')->countAllResults(),
            'pending_ot'     => $db->table('overtime_requests')->where('status','Pending')->countAllResults(),
            'pending_leave'  => $db->table('leave_applications')->where('status','Pending')->countAllResults(),
        ];

        $todaySchedules = $db->table('schedules s')
            ->select('s.*, d.full_name AS driver_name, r.route_name, b.plate_number')
            ->join('drivers d', 'd.driver_id = s.driver_id')
            ->join('routes r',  'r.route_id  = s.route_id')
            ->join('buses b',   'b.bus_id    = s.bus_id')
            ->where('s.schedule_date', $today)
            ->orderBy('s.expected_start')
            ->get()->getResultArray();

        return $this->render('Dashboard', 'supervisor/dashboard', [
            'stats'          => $stats,
            'todaySchedules' => $todaySchedules,
        ]);
    }

  // ------------------------------------------------------------------
    // SCHEDULES
    // ------------------------------------------------------------------
    public function schedules()
    {
        $db = \Config\Database::connect();

        // No date param = show ALL schedules (most recent first).
        // ?date=YYYY-MM-DD = filter to that specific day.
        $date = $this->request->getGet('date');   // null if not set

        $query = $db->table('schedules s')
            ->select('s.*, d.full_name AS driver_name, r.route_name,
                      r.origin, r.destination, b.plate_number')
            ->join('drivers d', 'd.driver_id = s.driver_id', 'left')   // LEFT: unassigned trips have driver_id = NULL
            ->join('routes r',  'r.route_id  = s.route_id')
            ->join('buses b',   'b.bus_id    = s.bus_id');

        if (!empty($date)) {
            $query->where('s.schedule_date', $date);
        }

        $rows = $query
            ->orderBy('s.schedule_date', 'DESC')
            ->orderBy('s.expected_start', 'ASC')
            ->get()->getResultArray();

        return $this->render('Schedules', 'supervisor/schedules', [
            'schedules'  => $rows,
            'filterDate' => $date,    // null when "show all"
        ]);
    }

    public function scheduleCreate()
    {
        $db = \Config\Database::connect();
        return $this->render('Create Schedule', 'supervisor/schedule_form', [
            'mode'    => 'create',
            'sched'   => null,
            'drivers' => $db->table('drivers')->where('status','active')->get()->getResultArray(),
            'routes'  => $db->table('routes')->get()->getResultArray(),
            'buses'   => $db->table('buses')->where('status !=', 'maintenance')->get()->getResultArray(),
        ]);
    }

    public function scheduleStore()
    {
        $db = \Config\Database::connect();
        $data = [
            'driver_id'      => (int)$this->request->getPost('driver_id'),
            'supervisor_id'  => session('user_id'),
            'bus_id'         => (int)$this->request->getPost('bus_id'),
            'route_id'       => (int)$this->request->getPost('route_id'),
            'schedule_date'  => $this->request->getPost('schedule_date'),
            'expected_start' => $this->request->getPost('expected_start'),
            'expected_end'   => $this->request->getPost('expected_end'),
            'job_status'     => 'Pending',
        ];

        if (in_array('', $data, true) || $data['driver_id']==0) {
            return redirect()->back()->withInput()
                ->with('flash', ['type'=>'danger','msg'=>'All fields are required.']);
        }

        // Block the assignment if the chosen driver is on approved leave that day.
        if ($this->driverOnLeave($data['driver_id'], $data['schedule_date'])) {
            $name = $db->table('drivers')
                ->where('driver_id', $data['driver_id'])
                ->get()->getRowArray()['full_name'] ?? 'This driver';
            return redirect()->back()->withInput()
                ->with('flash', ['type'=>'danger',
                    'msg'=>"{$name} is on approved leave on {$data['schedule_date']}. Pick another driver or change the date."]);
        }

        $db->table('schedules')->insert($data);

        return redirect()->to('/supervisor/schedules')
            ->with('flash', ['type'=>'success','msg'=>'Schedule created.']);
    }

    public function scheduleEdit($id)
    {
        $db = \Config\Database::connect();
        $sched = $db->table('schedules')->where('schedule_id',$id)->get()->getRowArray();
        if (!$sched) return redirect()->to('/supervisor/schedules');

        return $this->render('Edit Schedule', 'supervisor/schedule_form', [
            'mode'    => 'edit',
            'sched'   => $sched,
            'drivers' => $db->table('drivers')->where('status','active')->get()->getResultArray(),
            'routes'  => $db->table('routes')->get()->getResultArray(),
            'buses'   => $db->table('buses')->get()->getResultArray(),
        ]);
    }

    public function scheduleUpdate($id)
    {
        $db = \Config\Database::connect();

        $driverId     = (int)$this->request->getPost('driver_id');
        $scheduleDate = $this->request->getPost('schedule_date');

        // Block the assignment if the chosen driver is on approved leave that day.
        if ($driverId > 0 && $this->driverOnLeave($driverId, $scheduleDate)) {
            $name = $db->table('drivers')
                ->where('driver_id', $driverId)
                ->get()->getRowArray()['full_name'] ?? 'This driver';
            return redirect()->back()->withInput()
                ->with('flash', ['type'=>'danger',
                    'msg'=>"{$name} is on approved leave on {$scheduleDate}. Pick another driver or change the date."]);
        }

        $db->table('schedules')->where('schedule_id',$id)->update([
            'driver_id'      => $driverId,
            'bus_id'         => (int)$this->request->getPost('bus_id'),
            'route_id'       => (int)$this->request->getPost('route_id'),
            'schedule_date'  => $scheduleDate,
            'expected_start' => $this->request->getPost('expected_start'),
            'expected_end'   => $this->request->getPost('expected_end'),
        ]);
        return redirect()->to('/supervisor/schedules')
            ->with('flash',['type'=>'success','msg'=>'Schedule updated.']);
    }

    public function scheduleDelete($id)
    {
        $db = \Config\Database::connect();
        $db->table('schedules')->where('schedule_id',$id)->delete();
        return redirect()->to('/supervisor/schedules')
            ->with('flash',['type'=>'success','msg'=>'Schedule deleted.']);
    }

    // ------------------------------------------------------------------
    // OVERTIME
    // ------------------------------------------------------------------
    public function overtime()
    {
        $db = \Config\Database::connect();
        $rows = $db->table('overtime_requests ot')
            ->select('ot.*, s.schedule_date, s.expected_end, s.actual_end,
                      d.full_name AS driver_name, r.route_name')
            ->join('schedules s', 's.schedule_id = ot.schedule_id')
            ->join('drivers d',   'd.driver_id   = s.driver_id')
            ->join('routes r',    'r.route_id    = s.route_id')
            ->orderBy('ot.created_at','DESC')
            ->get()->getResultArray();

        return $this->render('Overtime Requests', 'supervisor/overtime', [
            'overtime' => $rows,
        ]);
    }

    public function overtimeReview($id)
    {
        $decision = $this->request->getPost('decision'); // 'Approved' or 'Rejected'
        if (!in_array($decision, ['Approved','Rejected'], true)) {
            return redirect()->to('/supervisor/overtime');
        }

        $db = \Config\Database::connect();
        $db->table('overtime_requests')->where('overtime_id',$id)->update([
            'status'        => $decision,
            'supervisor_id' => session('user_id'),
            'reviewed_at'   => date('Y-m-d H:i:s'),
        ]);

        return redirect()->to('/supervisor/overtime')
            ->with('flash',['type'=>'success','msg'=>"Overtime {$decision}."]);
    }

    // ------------------------------------------------------------------
    // LEAVE
    // ------------------------------------------------------------------
    public function leave()
    {
        $db = \Config\Database::connect();
        $rows = $db->table('leave_applications l')
            ->select('l.*, d.full_name AS driver_name')
            ->join('drivers d', 'd.driver_id = l.driver_id')
            ->orderBy('l.created_at','DESC')
            ->get()->getResultArray();

        return $this->render('Leave Applications', 'supervisor/leave', [
            'leaves' => $rows,
        ]);
    }

    public function leaveReview($id)
    {
        $decision = $this->request->getPost('decision');
        if (!in_array($decision, ['Approved','Rejected'], true)) {
            return redirect()->to('/supervisor/leave');
        }

        $db = \Config\Database::connect();

        // Get the leave details first (we need start/end dates and driver_id).
        $leave = $db->table('leave_applications')
            ->where('leave_id', $id)
            ->get()->getRowArray();

        if (!$leave) {
            return redirect()->to('/supervisor/leave');
        }

        // Mark the leave with the supervisor's decision.
        $db->table('leave_applications')->where('leave_id',$id)->update([
            'status'        => $decision,
            'supervisor_id' => session('user_id'),
            'reviewed_at'   => date('Y-m-d H:i:s'),
        ]);

        $releasedCount = 0;

        // If approved: auto-release this driver's FUTURE trips during the leave period.
        // Rules:
        //   - Only trips from today onwards (past trips remain attributed to the driver).
        //   - Only trips not yet started (actual_start IS NULL) — in-progress work is preserved.
        //   - Released trips become unassigned and re-enter the volunteer pool.
        if ($decision === 'Approved') {
            $today      = date('Y-m-d');
            $rangeStart = max($leave['start_date'], $today);
            $rangeEnd   = $leave['end_date'];

            // Only run if the leave still has future dates.
            if ($rangeStart <= $rangeEnd) {
                $db->table('schedules')
                    ->where('driver_id', $leave['driver_id'])
                    ->where('schedule_date >=', $rangeStart)
                    ->where('schedule_date <=', $rangeEnd)
                    ->where('actual_start IS NULL', null, false)
                    ->update([
                        'driver_id'  => null,
                        'job_status' => 'Pending',
                    ]);
                $releasedCount = $db->affectedRows();
            }
        }

        $flashMsg = "Leave {$decision}.";
        if ($releasedCount > 0) {
            $flashMsg .= " {$releasedCount} affected trip(s) released to volunteer pool.";
        }

        return redirect()->to('/supervisor/leave')
            ->with('flash',['type'=>'success','msg'=>$flashMsg]);
    }

    // ------------------------------------------------------------------
    // LIVE FLEET
    // ------------------------------------------------------------------
    public function fleet()
    {
        $db = \Config\Database::connect();
        $today = date('Y-m-d');

        $fleet = $db->table('buses b')
            ->select('
                b.bus_id, b.plate_number, b.mac_address, b.status AS bus_status,
                s.schedule_id, s.job_status, s.expected_start, s.expected_end,
                s.actual_start, s.actual_end, s.is_synced,
                d.full_name AS driver_name,
                r.route_name, r.origin, r.destination
            ')
            ->join('schedules s',
                "s.bus_id = b.bus_id AND s.schedule_date = '{$today}' AND s.job_status IN ('Pending','In-Progress')",
                'left')
            ->join('drivers d', 'd.driver_id = s.driver_id', 'left')
            ->join('routes r',  'r.route_id  = s.route_id',  'left')
            ->orderBy('b.plate_number')
            ->get()->getResultArray();

        return $this->render('Live Fleet', 'supervisor/fleet', ['fleet' => $fleet]);
    }

    // ------------------------------------------------------------------
    // CANCELLATION REQUESTS
    // ------------------------------------------------------------------
    public function cancellations()
    {
        $db = \Config\Database::connect();
        $rows = $db->table('cancel_requests cr')
            ->select('cr.*, d.full_name AS driver_name,
                      s.schedule_date, s.expected_start, s.expected_end,
                      r.route_name, b.plate_number')
            ->join('drivers d',   'd.driver_id   = cr.driver_id')
            ->join('schedules s', 's.schedule_id = cr.schedule_id')
            ->join('routes r',    'r.route_id    = s.route_id')
            ->join('buses b',     'b.bus_id      = s.bus_id')
            ->orderBy('cr.status', 'ASC')  // Pending first
            ->orderBy('cr.created_at', 'DESC')
            ->get()->getResultArray();

        return $this->render('Cancellation Requests', 'supervisor/cancellations', [
            'cancels' => $rows,
        ]);
    }

    public function cancelReview($id)
    {
        $decision = $this->request->getPost('decision');
        if (!in_array($decision, ['Approved','Rejected'], true)) {
            return redirect()->to('supervisor/cancellations');
        }

        $db = \Config\Database::connect();
        $cancel = $db->table('cancel_requests')
            ->where('cancel_id', $id)
            ->get()->getRowArray();

        if (!$cancel) {
            return redirect()->to('supervisor/cancellations');
        }

        $db->table('cancel_requests')->where('cancel_id', $id)->update([
            'status'        => $decision,
            'supervisor_id' => session('user_id'),
            'reviewed_at'   => date('Y-m-d H:i:s'),
        ]);

        // If approved, unassign the trip (driver_id = NULL).
        if ($decision === 'Approved') {
            $db->table('schedules')
                ->where('schedule_id', $cancel['schedule_id'])
                ->update([
                    'driver_id' => null,
                    'job_status' => 'Pending',
                ]);
        }

        return redirect()->to('supervisor/cancellations')
            ->with('flash', ['type'=>'success', 'msg' => "Cancellation {$decision}."]);
    }

    // ------------------------------------------------------------------
    // VOLUNTEER REQUESTS
    // ------------------------------------------------------------------
    public function volunteers()
    {
        $db = \Config\Database::connect();
        $rows = $db->table('volunteer_requests vr')
            ->select('vr.*, d.full_name AS driver_name,
                      s.schedule_date, s.expected_start, s.expected_end, s.driver_id AS current_driver_id,
                      r.route_name, b.plate_number')
            ->join('drivers d',   'd.driver_id   = vr.driver_id')
            ->join('schedules s', 's.schedule_id = vr.schedule_id')
            ->join('routes r',    'r.route_id    = s.route_id')
            ->join('buses b',     'b.bus_id      = s.bus_id')
            ->orderBy('vr.status', 'ASC')
            ->orderBy('vr.created_at', 'DESC')
            ->get()->getResultArray();

        return $this->render('Volunteer Requests', 'supervisor/volunteers', [
            'volunteers' => $rows,
        ]);
    }

    public function volunteerReview($id)
    {
        $decision = $this->request->getPost('decision');
        if (!in_array($decision, ['Approved','Rejected'], true)) {
            return redirect()->to('supervisor/volunteers');
        }

        $db = \Config\Database::connect();
        $vol = $db->table('volunteer_requests')
            ->where('volunteer_id', $id)
            ->get()->getRowArray();
        if (!$vol) return redirect()->to('supervisor/volunteers');

        $db->table('volunteer_requests')->where('volunteer_id', $id)->update([
            'status'        => $decision,
            'supervisor_id' => session('user_id'),
            'reviewed_at'   => date('Y-m-d H:i:s'),
        ]);

        if ($decision === 'Approved') {
            // Make sure the trip is still unassigned (race condition safety).
            $sched = $db->table('schedules')
                ->where('schedule_id', $vol['schedule_id'])
                ->get()->getRowArray();
            if ($sched && $sched['driver_id'] === null) {
                // Assign the volunteer.
                $db->table('schedules')
                    ->where('schedule_id', $vol['schedule_id'])
                    ->update(['driver_id' => $vol['driver_id']]);
                // Auto-reject all OTHER pending volunteers for this trip.
                $db->table('volunteer_requests')
                    ->where('schedule_id', $vol['schedule_id'])
                    ->where('status', 'Pending')
                    ->update([
                        'status'      => 'Auto-Rejected',
                        'reviewed_at' => date('Y-m-d H:i:s'),
                    ]);
                return redirect()->to('supervisor/volunteers')
                    ->with('flash', ['type'=>'success',
                        'msg' => 'Volunteer approved and trip assigned.']);
            } else {
                // Trip got assigned in the meantime — rollback approval.
                $db->table('volunteer_requests')->where('volunteer_id', $id)->update([
                    'status'      => 'Auto-Rejected',
                    'reviewed_at' => date('Y-m-d H:i:s'),
                ]);
                return redirect()->to('supervisor/volunteers')
                    ->with('flash', ['type'=>'warning',
                        'msg' => 'Trip is no longer unassigned. Auto-rejected.']);
            }
        }

        return redirect()->to('supervisor/volunteers')
            ->with('flash', ['type'=>'success', 'msg' => 'Volunteer rejected.']);
    }

    // ------------------------------------------------------------------
    // UNASSIGNED TRIPS POOL — manual assignment
    // ------------------------------------------------------------------
    public function unassigned()
    {
        $db = \Config\Database::connect();
        $today = date('Y-m-d');
        $rows = $db->table('schedules s')
            ->select('s.*, r.route_name, r.origin, r.destination, b.plate_number')
            ->join('routes r', 'r.route_id = s.route_id')
            ->join('buses b',  'b.bus_id   = s.bus_id')
            ->where('s.driver_id IS NULL', null, false)
            ->where('s.schedule_date >=', $today)
            ->orderBy('s.schedule_date', 'ASC')
            ->orderBy('s.expected_start', 'ASC')
            ->get()->getResultArray();

        $drivers = $db->table('drivers')
            ->where('status', 'active')
            ->orderBy('full_name')
            ->get()->getResultArray();

        return $this->render('Unassigned Trips', 'supervisor/unassigned', [
            'unassigned' => $rows,
            'drivers'    => $drivers,
        ]);
    }

    public function assignUnassigned($scheduleId)
    {
        $driverId = (int)$this->request->getPost('driver_id');
        if ($driverId <= 0) {
            return redirect()->to('supervisor/unassigned')
                ->with('flash', ['type'=>'danger', 'msg'=>'Pick a driver.']);
        }

        $db = \Config\Database::connect();

        // Look up the trip's date so we can check leave coverage.
        $sched = $db->table('schedules')
            ->where('schedule_id', $scheduleId)
            ->get()->getRowArray();

        if (!$sched) {
            return redirect()->to('supervisor/unassigned')
                ->with('flash', ['type'=>'danger', 'msg'=>'Schedule not found.']);
        }

        // Block the assignment if the driver is on approved leave that day.
        if ($this->driverOnLeave($driverId, $sched['schedule_date'])) {
            $name = $db->table('drivers')
                ->where('driver_id', $driverId)
                ->get()->getRowArray()['full_name'] ?? 'This driver';
            return redirect()->to('supervisor/unassigned')
                ->with('flash', ['type'=>'danger',
                    'msg'=>"{$name} is on approved leave on {$sched['schedule_date']}. Pick another driver."]);
        }

        $db->table('schedules')
            ->where('schedule_id', $scheduleId)
            ->where('driver_id IS NULL', null, false)
            ->update(['driver_id' => $driverId]);

        if ($db->affectedRows() === 0) {
            return redirect()->to('supervisor/unassigned')
                ->with('flash', ['type'=>'warning',
                    'msg'=>'Trip was already assigned by someone else.']);
        }

        return redirect()->to('supervisor/unassigned')
            ->with('flash', ['type'=>'success', 'msg'=>'Driver assigned.']);
    }
}
