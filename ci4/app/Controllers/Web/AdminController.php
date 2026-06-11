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
    
    // Date range from query string, default to last 30 days
    $endDate = $this->request->getGet('end_date') ?? date('Y-m-d');
    $startDate = $this->request->getGet('start_date') ?? date('Y-m-d', strtotime('-30 days'));
    
    // Get all active drivers
    $drivers = $db->table('drivers')
        ->select('driver_id, full_name, email, phone, created_at')
        ->where('status', 'active')
        ->orderBy('full_name', 'ASC')
        ->get()
        ->getResultArray();
    
    $reports = [];
    
    foreach ($drivers as $driver) {
        $driverId = (int)$driver['driver_id'];
        
        // METRIC 1: Punctuality — % of completed trips within 5 min of expected
        $tripQuery = $db->query("
            SELECT 
                COUNT(*) as total_trips,
                SUM(CASE 
                    WHEN actual_start IS NOT NULL 
                    AND actual_end IS NOT NULL
                    AND ABS(TIMESTAMPDIFF(MINUTE, actual_start, CONCAT(schedule_date, ' ', expected_start))) <= 5
                    AND ABS(TIMESTAMPDIFF(MINUTE, actual_end, CONCAT(schedule_date, ' ', expected_end))) <= 5
                    THEN 1 ELSE 0 END
                ) as on_time_trips
            FROM schedules
            WHERE driver_id = ? 
            AND schedule_date BETWEEN ? AND ?
            AND job_status = 'Completed'
        ", [$driverId, $startDate, $endDate])->getRowArray();
        
        $totalTrips = (int)($tripQuery['total_trips'] ?? 0);
        $onTimeTrips = (int)($tripQuery['on_time_trips'] ?? 0);
        $punctualityPct = $totalTrips > 0 ? ($onTimeTrips / $totalTrips) * 100 : 0;
        
        // METRIC 2: Availability — inverse of approved leave days in range
        $leaveDays = $db->query("
            SELECT COALESCE(SUM(DATEDIFF(end_date, start_date) + 1), 0) as days
            FROM leave_applications
            WHERE driver_id = ?
            AND status = 'Approved'
            AND start_date <= ?
            AND end_date >= ?
        ", [$driverId, $endDate, $startDate])->getRowArray();
        
        $totalDaysInRange = (strtotime($endDate) - strtotime($startDate)) / 86400 + 1;
        $leaveDaysCount = (int)$leaveDays['days'];
        $availabilityPct = max(0, (1 - ($leaveDaysCount / $totalDaysInRange)) * 100);
        
        // METRIC 3: Cancellation rate — inverse (fewer approved cancels = higher score)
        $cancelCount = $db->query("
            SELECT COUNT(*) as cnt
            FROM cancel_requests cr
            JOIN schedules s ON cr.schedule_id = s.schedule_id
            WHERE cr.driver_id = ?
            AND cr.status = 'Approved'
            AND s.schedule_date BETWEEN ? AND ?
        ", [$driverId, $startDate, $endDate])->getRowArray();
        
        $cancelTrips = (int)$cancelCount['cnt'];
        $totalScheduledTrips = $totalTrips + $cancelTrips;
        $cancellationPct = $totalScheduledTrips > 0 
            ? (1 - ($cancelTrips / $totalScheduledTrips)) * 100 
            : 100;
        
        // METRIC 4: Volunteer contributions — count of approved volunteer pickups
        $volunteerCount = $db->query("
            SELECT COUNT(*) as cnt
            FROM volunteer_requests vr
            JOIN schedules s ON vr.schedule_id = s.schedule_id
            WHERE vr.driver_id = ?
            AND vr.status = 'Approved'
            AND s.schedule_date BETWEEN ? AND ?
        ", [$driverId, $startDate, $endDate])->getRowArray();
        
        $volunteerTrips = (int)$volunteerCount['cnt'];
        $weeksInRange = max(1, $totalDaysInRange / 7);
        $volunteerPct = min(100, ($volunteerTrips / $weeksInRange) * 100);
        
        // METRIC 5: Total trips completed — productivity indicator
        $tripsPerWeek = $totalTrips / $weeksInRange;
        $totalTripsPct = min(100, ($tripsPerWeek / 5) * 100);
        
        // METRIC 6: Length of service — months since registration, capped at 24
        $monthsService = max(0, (strtotime($endDate) - strtotime($driver['created_at'])) / 2592000);
        $serviceP = min(100, ($monthsService / 24) * 100);
        
        // OVERALL: equal weights = 16.67% each
        $overallScore = ($punctualityPct + $availabilityPct + $cancellationPct 
                       + $volunteerPct + $totalTripsPct + $serviceP) / 6;
        
        // Determine rating band
        $rating = 'Needs improvement';
        $ratingClass = 'danger';
        if ($overallScore >= 90) { $rating = 'Excellent'; $ratingClass = 'success'; }
        elseif ($overallScore >= 75) { $rating = 'Good'; $ratingClass = 'primary'; }
        elseif ($overallScore >= 60) { $rating = 'Fair'; $ratingClass = 'warning'; }
        
        $reports[] = [
            'driver_id' => $driverId,
            'name' => $driver['full_name'],
            'email' => $driver['email'],
            'total_trips' => $totalTrips,
            'on_time_trips' => $onTimeTrips,
            'cancel_trips' => $cancelTrips,
            'volunteer_trips' => $volunteerTrips,
            'leave_days' => $leaveDaysCount,
            'months_service' => round($monthsService, 1),
            'punctuality_pct' => round($punctualityPct, 1),
            'availability_pct' => round($availabilityPct, 1),
            'cancellation_pct' => round($cancellationPct, 1),
            'volunteer_pct' => round($volunteerPct, 1),
            'total_trips_pct' => round($totalTripsPct, 1),
            'service_pct' => round($serviceP, 1),
            'overall_score' => round($overallScore, 1),
            'rating' => $rating,
            'rating_class' => $ratingClass,
        ];
    }
    
    // Sort by overall score descending
    usort($reports, fn($a, $b) => $b['overall_score'] <=> $a['overall_score']);
    
    $data = [
    'reports' => $reports,
    'start_date' => $startDate,
    'end_date' => $endDate,
    'total_drivers' => count($reports),
    'date_range_days' => (int)$totalDaysInRange,
];

return view('layouts/main', [
    'title'    => 'Performance Reports',
    'role'     => 'admin',
    'userName' => session('user_name') ?? 'Admin',
    'content'  => view('admin/reports', $data),
]);
}
}
