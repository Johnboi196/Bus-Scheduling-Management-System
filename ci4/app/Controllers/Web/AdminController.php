<?php

namespace App\Controllers\Web;

use CodeIgniter\Controller;

/**
 * AdminController
 * --------------------------------------------------------------------
 * Maps to Use Case Diagram (Admin):
 *   - Create/delete drivers and supervisors
 *   - Manage bus hardware (register MAC addresses) ← critical setup
 *   - Manage routes & terminals
 *   - Generate system reports
 */
class AdminController extends Controller
{
    private function render(string $title, string $contentView, array $data = [])
    {
        $data['title']    = $title;
        $data['role']     = 'admin';
        $data['userName'] = session('user_name');
        $data['content']  = view($contentView, $data);
        return view('layouts/main', $data);
    }

    // ------------------------------------------------------------------
    // DASHBOARD
    // ------------------------------------------------------------------
    public function dashboard()
    {
        $db = \Config\Database::connect();
        $stats = [
            'drivers'     => $db->table('drivers')->countAllResults(),
            'supervisors' => $db->table('supervisors')->countAllResults(),
            'buses'       => $db->table('buses')->countAllResults(),
            'routes'      => $db->table('routes')->countAllResults(),
            'trips_today' => $db->table('schedules')->where('schedule_date',date('Y-m-d'))->countAllResults(),
            'completed_today' => $db->table('schedules')->where('schedule_date',date('Y-m-d'))
                                    ->where('job_status','Completed')->countAllResults(),
        ];
        return $this->render('Admin Dashboard', 'admin/dashboard', ['stats'=>$stats]);
    }

    // ------------------------------------------------------------------
    // DRIVERS
    // ------------------------------------------------------------------
    public function drivers()
    {
        $db = \Config\Database::connect();
        $rows = $db->table('drivers')->orderBy('full_name')->get()->getResultArray();
        return $this->render('Drivers', 'admin/drivers', ['drivers'=>$rows]);
    }

    public function driverStore()
    {
        $name   = trim($this->request->getPost('full_name'));
        $email  = trim($this->request->getPost('email'));
        $phone  = trim($this->request->getPost('phone'));
        $passwd = $this->request->getPost('password');

        if ($name==='' || $email==='' || strlen($passwd) < 6) {
            return redirect()->back()
                ->with('flash',['type'=>'danger','msg'=>'Name, email, and a 6+ char password are required.']);
        }

        $db = \Config\Database::connect();
        try {
            $db->table('drivers')->insert([
                'full_name' => $name,
                'email'     => $email,
                'phone'     => $phone ?: null,
                'password'  => password_hash($passwd, PASSWORD_BCRYPT),
                'status'    => 'active',
            ]);
        } catch (\Throwable $e) {
            return redirect()->back()
                ->with('flash',['type'=>'danger','msg'=>'Email already exists.']);
        }
        return redirect()->to('/admin/drivers')
            ->with('flash',['type'=>'success','msg'=>'Driver created.']);
    }

    public function driverDelete($id)
    {
        $db = \Config\Database::connect();
        // Soft-delete approach: deactivate instead of hard-delete to keep schedule history intact.
        $db->table('drivers')->where('driver_id',$id)->update(['status'=>'inactive']);
        return redirect()->to('/admin/drivers')
            ->with('flash',['type'=>'success','msg'=>'Driver deactivated.']);
    }

    // ------------------------------------------------------------------
    // SUPERVISORS
    // ------------------------------------------------------------------
    public function supervisors()
    {
        $db = \Config\Database::connect();
        $rows = $db->table('supervisors')->orderBy('full_name')->get()->getResultArray();
        return $this->render('Supervisors', 'admin/supervisors', ['supervisors'=>$rows]);
    }

    public function supervisorStore()
    {
        $name  = trim($this->request->getPost('full_name'));
        $email = trim($this->request->getPost('email'));
        $emp   = trim($this->request->getPost('employee_id'));
        $pass  = $this->request->getPost('password');

        if ($name==='' || $email==='' || $emp==='' || strlen($pass) < 6) {
            return redirect()->back()
                ->with('flash',['type'=>'danger','msg'=>'All fields are required (password 6+ chars).']);
        }

        $db = \Config\Database::connect();
        try {
            $db->table('supervisors')->insert([
                'full_name'   => $name,
                'email'       => $email,
                'employee_id' => $emp,
                'password'    => password_hash($pass, PASSWORD_BCRYPT),
            ]);
        } catch (\Throwable $e) {
            return redirect()->back()
                ->with('flash',['type'=>'danger','msg'=>'Email or employee ID already exists.']);
        }
        return redirect()->to('/admin/supervisors')
            ->with('flash',['type'=>'success','msg'=>'Supervisor created.']);
    }

    public function supervisorDelete($id)
    {
        $db = \Config\Database::connect();
        // Foreign keys on schedules/overtime mean hard-delete may fail.
        // Use try/catch and inform the admin if it's blocked.
        try {
            $db->table('supervisors')->where('supervisor_id',$id)->delete();
            return redirect()->to('/admin/supervisors')
                ->with('flash',['type'=>'success','msg'=>'Supervisor removed.']);
        } catch (\Throwable $e) {
            return redirect()->to('/admin/supervisors')
                ->with('flash',['type'=>'danger','msg'=>'Cannot delete — supervisor has existing records.']);
        }
    }

    // ------------------------------------------------------------------
    // BUSES (Hardware/MAC registration)
    // ------------------------------------------------------------------
    public function buses()
    {
        $db = \Config\Database::connect();
        $rows = $db->table('buses')->orderBy('plate_number')->get()->getResultArray();
        return $this->render('Buses (Hardware)', 'admin/buses', ['buses'=>$rows]);
    }

    public function busStore()
    {
        $plate  = strtoupper(trim($this->request->getPost('plate_number') ?? ''));
        $mac    = strtoupper(trim($this->request->getPost('mac_address')  ?? ''));
        $status = $this->request->getPost('status') ?: 'available';

        if ($plate === '') {
            return redirect()->back()
                ->with('flash',['type'=>'danger','msg'=>'Plate number is required.']);
        }
        if ($mac === '') {
            return redirect()->back()
                ->with('flash',['type'=>'danger','msg'=>'MAC address is required.']);
        }

        $db = \Config\Database::connect();

        // Explicit checks so we can return useful error messages, instead of
        // catching a generic exception and assuming what went wrong.
        if ($db->table('buses')->where('plate_number', $plate)->countAllResults() > 0) {
            return redirect()->back()
                ->with('flash',['type'=>'danger','msg'=>'Plate number already exists.']);
        }
        if ($db->table('buses')->where('mac_address', $mac)->countAllResults() > 0) {
            return redirect()->back()
                ->with('flash',['type'=>'danger','msg'=>'MAC address already registered.']);
        }

        try {
            $db->table('buses')->insert([
                'plate_number' => $plate,
                'mac_address'  => $mac,
                'status'       => $status,
            ]);
        } catch (\Throwable $e) {
            return redirect()->back()
                ->with('flash',['type'=>'danger','msg'=>'Could not register bus: ' . $e->getMessage()]);
        }
        return redirect()->to('admin/buses')
            ->with('flash',['type'=>'success','msg'=>'Bus registered.']);
    }

    public function busDelete($id)
    {
        $db = \Config\Database::connect();
        try {
            $db->table('buses')->where('bus_id',$id)->delete();
            return redirect()->to('admin/buses')
                ->with('flash',['type'=>'success','msg'=>'Bus removed.']);
        } catch (\Throwable $e) {
            return redirect()->to('admin/buses')
                ->with('flash',['type'=>'danger','msg'=>'Cannot delete — bus has existing schedules.']);
        }
    }

    // ------------------------------------------------------------------
    // ROUTES
    // ------------------------------------------------------------------
    public function routesList()
    {
        $db = \Config\Database::connect();
        $rows = $db->table('routes')->orderBy('route_name')->get()->getResultArray();
        return $this->render('Routes', 'admin/routes', ['routes'=>$rows]);
    }

    public function routeStore()
    {
        $name = trim($this->request->getPost('route_name'));
        $org  = trim($this->request->getPost('origin'));
        $dst  = trim($this->request->getPost('destination'));
        $km   = (float)($this->request->getPost('distance_km') ?: 0);

        if ($name==='' || $org==='' || $dst==='') {
            return redirect()->back()
                ->with('flash',['type'=>'danger','msg'=>'All fields required.']);
        }

        $db = \Config\Database::connect();
        $db->table('routes')->insert([
            'route_name'  => $name,
            'origin'      => $org,
            'destination' => $dst,
            'distance_km' => $km > 0 ? $km : null,
        ]);
        return redirect()->to('/admin/routes')
            ->with('flash',['type'=>'success','msg'=>'Route added.']);
    }

    public function routeDelete($id)
    {
        $db = \Config\Database::connect();
        try {
            $db->table('routes')->where('route_id',$id)->delete();
            return redirect()->to('/admin/routes')
                ->with('flash',['type'=>'success','msg'=>'Route removed.']);
        } catch (\Throwable $e) {
            return redirect()->to('/admin/routes')
                ->with('flash',['type'=>'danger','msg'=>'Cannot delete — route in use by schedules.']);
        }
    }

    // ------------------------------------------------------------------
    // REPORTS
    // ------------------------------------------------------------------
    public function reports()
    {
        $db = \Config\Database::connect();
        $from = $this->request->getGet('from') ?: date('Y-m-d', strtotime('-7 days'));
        $to   = $this->request->getGet('to')   ?: date('Y-m-d');

        // Trip completion by day
        $dailyTrips = $db->table('schedules')
            ->select("schedule_date, COUNT(*) total,
                      SUM(job_status='Completed') completed,
                      SUM(job_status='In-Progress') in_progress,
                      SUM(job_status='Pending') pending,
                      SUM(job_status='Cancelled') cancelled")
            ->where('schedule_date >=',$from)
            ->where('schedule_date <=',$to)
            ->groupBy('schedule_date')
            ->orderBy('schedule_date','DESC')
            ->get()->getResultArray();

        // Overtime summary
        $overtimeSummary = $db->table('overtime_requests ot')
            ->select('d.full_name AS driver_name,
                      COUNT(*) AS total_requests,
                      SUM(ot.extra_minutes) AS total_minutes,
                      SUM(ot.status="Approved") AS approved_count')
            ->join('schedules s', 's.schedule_id = ot.schedule_id')
            ->join('drivers d',   'd.driver_id   = s.driver_id')
            ->where('s.schedule_date >=', $from)
            ->where('s.schedule_date <=', $to)
            ->groupBy('d.driver_id')
            ->orderBy('total_minutes','DESC')
            ->get()->getResultArray();

        // Leave summary
        $leaveSummary = $db->table('leave_applications')
            ->select("status, COUNT(*) cnt")
            ->where('start_date >=',$from)
            ->where('start_date <=',$to)
            ->groupBy('status')
            ->get()->getResultArray();

        return $this->render('Reports', 'admin/reports', [
            'from'            => $from,
            'to'              => $to,
            'dailyTrips'      => $dailyTrips,
            'overtimeSummary' => $overtimeSummary,
            'leaveSummary'    => $leaveSummary,
        ]);
    }
}
