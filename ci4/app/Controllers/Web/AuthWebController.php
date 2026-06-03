<?php

namespace App\Controllers\Web;

use CodeIgniter\Controller;

/**
 * AuthWebController — browser session login for supervisors & admins.
 *
 * Supervisors and admins log in with their employee_id (e.g. "SUP001",
 * "ADM001"), matching the Use Case Diagram. Drivers continue to use
 * email through the Flutter app (separate API controller).
 *
 * The web dashboard uses CI4's session() so we get standard cookie-based
 * auth and CSRF protection on forms. Same user tables, different lookup field.
 */
class AuthWebController extends Controller
{
    /** GET / and GET /login → show form */
    public function showLogin()
    {
        if (session('user_id')) {
            return redirect()->to(session('role') === 'admin'
                ? 'admin/dashboard'
                : 'supervisor/dashboard');
        }
        return view('auth/login');
    }

    /** POST /login */
    public function doLogin()
    {
        // The form sends "employee_id" now (was "email" before).
        $employeeId = trim($this->request->getPost('employee_id') ?? '');
        $password   = (string)($this->request->getPost('password') ?? '');
        $role       = $this->request->getPost('role') ?? 'supervisor';

        if ($employeeId === '' || $password === '') {
            return redirect()->back()->withInput()
                ->with('error', 'Employee ID and password are required.');
        }

        $tables = [
            'supervisor' => ['table' => 'supervisors', 'id' => 'supervisor_id'],
            'admin'      => ['table' => 'admins',      'id' => 'admin_id'],
        ];
        if (!isset($tables[$role])) {
            return redirect()->back()->with('error', 'Invalid role.');
        }

        $db   = \Config\Database::connect();
        $user = $db->table($tables[$role]['table'])
                   ->where('employee_id', $employeeId)
                   ->get()->getRowArray();

        if (!$user || !password_verify($password, $user['password'])) {
            log_message('warning', "Web login failed: {$role}/{$employeeId}");
            return redirect()->back()->withInput()
                ->with('error', 'Invalid credentials.');
        }

        // Establish session.
        session()->set([
            'user_id'     => $user[$tables[$role]['id']],
            'user_name'   => $user['full_name'],
            'employee_id' => $user['employee_id'],
            'role'        => $role,
            'logged_in'   => true,
        ]);

        log_message('info', "Web login success: {$role}/{$employeeId}");

        return redirect()->to($role === 'admin'
            ? 'admin/dashboard'
            : 'supervisor/dashboard');
    }

    /** GET /logout */
    public function logout()
    {
        session()->destroy();
        return redirect()->to('login')->with('flash', [
            'type' => 'success', 'msg' => 'You have been logged out.'
        ]);
    }
}
