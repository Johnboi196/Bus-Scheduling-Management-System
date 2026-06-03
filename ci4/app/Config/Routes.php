<?php

use CodeIgniter\Router\RouteCollection;

/** @var RouteCollection $routes */

// =====================================================================
// PUBLIC PAGES
// =====================================================================
$routes->get('/',       'Web\AuthWebController::showLogin');
$routes->get('login',   'Web\AuthWebController::showLogin');
$routes->post('login',  'Web\AuthWebController::doLogin');
$routes->get('logout',  'Web\AuthWebController::logout');

// =====================================================================
// SUPERVISOR DASHBOARD  (protected by role:supervisor filter)
// =====================================================================
$routes->group('supervisor', ['filter' => 'role:supervisor', 'namespace' => 'App\Controllers\Web'], static function ($routes) {
    $routes->get('dashboard',          'SupervisorController::dashboard');

    // Schedules CRUD
    $routes->get('schedules',          'SupervisorController::schedules');
    $routes->get('schedules/create',   'SupervisorController::scheduleCreate');
    $routes->post('schedules/store',   'SupervisorController::scheduleStore');
    $routes->get('schedules/edit/(:num)',  'SupervisorController::scheduleEdit/$1');
    $routes->post('schedules/update/(:num)','SupervisorController::scheduleUpdate/$1');
    $routes->get('schedules/delete/(:num)','SupervisorController::scheduleDelete/$1');

    // Overtime review
    $routes->get('overtime',           'SupervisorController::overtime');
    $routes->post('overtime/review/(:num)', 'SupervisorController::overtimeReview/$1');

    // Leave review
    $routes->get('leave',              'SupervisorController::leave');
    $routes->post('leave/review/(:num)','SupervisorController::leaveReview/$1');

    // Cancellation review
    $routes->get('cancellations',                'SupervisorController::cancellations');
    $routes->post('cancellations/review/(:num)', 'SupervisorController::cancelReview/$1');

    // Volunteer review
    $routes->get('volunteers',                'SupervisorController::volunteers');
    $routes->post('volunteers/review/(:num)', 'SupervisorController::volunteerReview/$1');

    // Unassigned trips pool
    $routes->get('unassigned',                'SupervisorController::unassigned');
    $routes->post('unassigned/assign/(:num)', 'SupervisorController::assignUnassigned/$1');

    // Live fleet
    $routes->get('fleet',              'SupervisorController::fleet');
});

// =====================================================================
// ADMIN DASHBOARD  (protected by role:admin filter)
// =====================================================================
$routes->group('admin', ['filter' => 'role:admin', 'namespace' => 'App\Controllers\Web'], static function ($routes) {
    $routes->get('dashboard',     'AdminController::dashboard');

    // Drivers
    $routes->get('drivers',                 'AdminController::drivers');
    $routes->post('drivers/store',          'AdminController::driverStore');
    $routes->get('drivers/delete/(:num)',   'AdminController::driverDelete/$1');

    // Supervisors
    $routes->get('supervisors',                'AdminController::supervisors');
    $routes->post('supervisors/store',         'AdminController::supervisorStore');
    $routes->get('supervisors/delete/(:num)',  'AdminController::supervisorDelete/$1');

    // Buses (hardware/MAC management)
    $routes->get('buses',              'AdminController::buses');
    $routes->post('buses/store',       'AdminController::busStore');
    $routes->get('buses/delete/(:num)','AdminController::busDelete/$1');

    // Routes
    $routes->get('routes',              'AdminController::routesList');
    $routes->post('routes/store',       'AdminController::routeStore');
    $routes->get('routes/delete/(:num)','AdminController::routeDelete/$1');

    // Reports
    $routes->get('reports', 'AdminController::reports');
});

// =====================================================================
// API ROUTES (untouched — Flutter app uses these)
// =====================================================================
$routes->group('api', ['namespace' => 'App\Controllers'], static function ($routes) {
    $routes->post('auth/login',                  'AuthController::login');
    $routes->post('auth/logout',                 'AuthController::logout');
    $routes->get('schedule/byMac/(:segment)',    'ScheduleController::fetchByMac/$1');
    $routes->get('schedule/byDriver/(:num)',     'ScheduleController::fetchByDriver/$1');
    $routes->get('schedule/history/(:num)',      'ScheduleController::history/$1');
    $routes->post('schedule/updateStatus',       'ScheduleController::updateStatus');
    $routes->post('sync/push',                   'SyncController::syncCachedData');
    $routes->post('overtime/request',            'OvertimeController::create');
    $routes->post('leave/apply',                 'LeaveController::apply');
    $routes->get('leave/byDriver/(:num)',        'LeaveController::byDriver/$1');

    // NEW: Cancel a trip
    $routes->post('cancel/request',              'CancelController::create');
    $routes->get('cancel/byDriver/(:num)',       'CancelController::byDriver/$1');

    // NEW: Volunteer for an unassigned trip
    $routes->get('volunteer/available',          'VolunteerController::available');
    $routes->post('volunteer/request',           'VolunteerController::create');
    $routes->get('volunteer/byDriver/(:num)',    'VolunteerController::byDriver/$1');
});
