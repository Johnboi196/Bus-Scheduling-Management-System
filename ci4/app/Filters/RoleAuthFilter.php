<?php

namespace App\Filters;

use CodeIgniter\HTTP\RequestInterface;
use CodeIgniter\HTTP\ResponseInterface;
use CodeIgniter\Filters\FilterInterface;

/**
 * RoleAuthFilter
 * Protects /supervisor/* and /admin/* routes. Pass the required role
 * as the filter argument:  ['filter' => 'role:supervisor']
 *
 * Register in Config/Filters.php (see comments in that file).
 */
class RoleAuthFilter implements FilterInterface
{
    public function before(RequestInterface $request, $arguments = null)
    {
        $session = session();

        if (!$session->get('logged_in')) {
            return redirect()->to('/login')
                ->with('error', 'Please log in to continue.');
        }

        // If a role was specified, enforce it.
        if (!empty($arguments)) {
            $required = $arguments[0]; // 'supervisor' or 'admin'
            if ($session->get('role') !== $required) {
                return redirect()->to('/login')
                    ->with('error', 'Access denied for this area.');
            }
        }
    }

    public function after(RequestInterface $request, ResponseInterface $response, $arguments = null)
    {
        // Nothing to do.
    }
}
