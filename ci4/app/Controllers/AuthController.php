<?php

namespace App\Controllers;

use CodeIgniter\RESTful\ResourceController;
use CodeIgniter\HTTP\ResponseInterface;

/**
 * AuthController
 * ----------------------------------------------------------------------
 * Handles login for Drivers, Supervisors, and Admins.
 * Maps to Use Case Diagram: "Login account for driver / staff / admin".
 * Maps to Sequence Diagram step 1: "Driver Login & OTP".
 *
 * Security:
 *   - Passwords stored as bcrypt hashes (password_hash).
 *   - Login uses password_verify (NEVER plain string compare).
 *   - A simple session token is returned. For production, swap for JWT.
 */
class AuthController extends ResourceController
{
    protected $format = 'json';

    /**
     * POST /api/auth/login
     * Body (JSON): { "email": "...", "password": "...", "role": "driver|supervisor|admin" }
     */
    public function login()
    {
        $input = $this->request->getJSON(true) ?? $this->request->getPost();

        $email    = trim($input['email']    ?? '');
        $password = (string)($input['password'] ?? '');
        $role     = strtolower($input['role'] ?? 'driver');

        if ($email === '' || $password === '') {
            return $this->failValidationErrors('Email and password are required.');
        }

        // Pick the right table for the role.
        $map = [
            'driver'     => ['table' => 'drivers',     'idField' => 'driver_id'],
            'supervisor' => ['table' => 'supervisors', 'idField' => 'supervisor_id'],
            'admin'      => ['table' => 'admins',      'idField' => 'admin_id'],
        ];
        if (!isset($map[$role])) {
            return $this->failValidationErrors('Invalid role.');
        }

        $db    = \Config\Database::connect();
        $user  = $db->table($map[$role]['table'])
                    ->where('email', $email)
                    ->get()
                    ->getRowArray();

        // Generic failure message - don't leak whether email exists.
        if (!$user || !password_verify($password, $user['password'])) {
            log_message('warning', "Failed login attempt for {$role}: {$email}");
            return $this->failUnauthorized('Invalid credentials.');
        }

        // Generate a session token (simple random; replace with JWT for prod).
        $token = bin2hex(random_bytes(32));

        // Hide the hash before returning.
        unset($user['password']);

        log_message('info', "Login success {$role}: {$email}");

        return $this->respond([
            'status'       => 'success',
            'message'      => 'Login successful.',
            'sessionToken' => $token,
            'role'         => $role,
            'user'         => $user,
        ]);
    }

    /**
     * POST /api/auth/logout
     * Stateless: client simply discards the token. Here for API completeness.
     */
    public function logout()
    {
        return $this->respond(['status' => 'success', 'message' => 'Logged out.']);
    }
}
