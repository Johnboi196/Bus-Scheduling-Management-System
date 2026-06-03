<?php
/**
 * Shared layout for all dashboard pages.
 * Uses site_url() helper so links work no matter what subfolder
 * CodeIgniter is hosted under (e.g. /ci4/public/).
 */
$role     = $role     ?? 'supervisor';
$userName = $userName ?? 'User';
$title    = $title    ?? 'Smart Bus';
$flash    = session()->getFlashdata('flash');

$supLinks = [
    ['url' => 'supervisor/dashboard',     'icon' => 'speedometer2',   'label' => 'Dashboard'],
    ['url' => 'supervisor/schedules',     'icon' => 'calendar3',      'label' => 'Schedules'],
    ['url' => 'supervisor/unassigned',    'icon' => 'inbox',          'label' => 'Unassigned Trips'],
    ['url' => 'supervisor/overtime',      'icon' => 'clock-history',  'label' => 'Overtime'],
    ['url' => 'supervisor/leave',         'icon' => 'envelope',       'label' => 'Leave'],
    ['url' => 'supervisor/cancellations', 'icon' => 'x-circle',       'label' => 'Cancellations'],
    ['url' => 'supervisor/volunteers',    'icon' => 'hand-thumbs-up', 'label' => 'Volunteers'],
    ['url' => 'supervisor/fleet',         'icon' => 'truck',          'label' => 'Live Fleet'],
];
$adminLinks = [
    ['url' => 'admin/dashboard',   'icon' => 'speedometer2', 'label' => 'Dashboard'],
    ['url' => 'admin/drivers',     'icon' => 'people',       'label' => 'Drivers'],
    ['url' => 'admin/supervisors', 'icon' => 'person-badge', 'label' => 'Supervisors'],
    ['url' => 'admin/buses',       'icon' => 'bus-front',    'label' => 'Buses'],
    ['url' => 'admin/routes',      'icon' => 'signpost-2',   'label' => 'Routes'],
    ['url' => 'admin/reports',     'icon' => 'graph-up',     'label' => 'Reports'],
];
$links = $role === 'admin' ? $adminLinks : $supLinks;
?>
<!doctype html>
<html lang="en">
<head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title><?= esc($title) ?> · Smart Bus</title>
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.2/dist/css/bootstrap.min.css" rel="stylesheet">
    <link href="https://cdn.jsdelivr.net/npm/bootstrap-icons@1.11.1/font/bootstrap-icons.min.css" rel="stylesheet">
    <style>
        body { background:#f4f6fa; }
         /* .sidebar {
            min-height: 100vh; background:#1f2937; color:#cbd5e1;
            width: 240px; position: fixed; top:0; left:0; padding: 16px 0;
            overflow-y: auto;
        }
        .sidebar .brand { color:#fff; font-weight:600; padding:0 20px 16px; border-bottom:1px solid #374151; }
        .sidebar a { color:#cbd5e1; text-decoration:none; display:flex; align-items:center;
                     gap:10px; padding:10px 20px; font-size:14px; }
        .sidebar a:hover, .sidebar a.active { background:#374151; color:#fff; } */
        .main { margin-left: 240px; padding: 24px; }
        .sidebar {
            min-height: 100vh; background:#6B0E2F; color:#F5D5DE;
            width: 240px; position: fixed; top:0; left:0; padding: 16px 0;
            overflow-y: auto;
        }
        /* .sidebar .brand {
            color:#fff; font-weight:600; padding:0 20px 16px;
            border-bottom:1px solid #4A0820;
            display:flex; align-items:center; justify-content:center;
        } */
        .sidebar .brand {
            background: #ffe2ec;
            padding: 16px 20px;
            margin: -16px 0 0 0;
            border-bottom: 1px solid #4A0820;
            display:flex; align-items:center; justify-content:center;
            }
        .sidebar .brand img { max-width: 180px; height: auto; }
        .sidebar a {
            color:#F5D5DE; text-decoration:none; display:flex; align-items:center;
            gap:10px; padding:10px 20px; font-size:14px;
            border-left: 3px solid transparent;
        }
        .sidebar a:hover { background:#5A0825; color:#fff; }

        .sidebar a.active {
            background:#4A0820; color:#fff;
            border-left-color:#C9942D;
        }

        .topbar { background:#fff; padding:12px 20px; border-radius:8px; margin-bottom:20px;
                  display:flex; justify-content:space-between; align-items:center;
                  box-shadow: 0 1px 2px rgba(0,0,0,0.05); }
        .card { border:none; box-shadow: 0 1px 3px rgba(0,0,0,0.06); }
        .stat-card { border-left: 4px solid #0d6efd; }
        .stat-card.warn  { border-left-color: #ffc107; }
        .stat-card.ok    { border-left-color: #198754; }
        .stat-card.danger{ border-left-color: #dc3545; }
    </style>
</head>
<body>
<nav class="sidebar">
    <div class="brand"><img src="<?= base_url('assets/img/logo.png') ?>"
         alt="Smart Bus"
         style="height:24px;width:auto;vertical-align:middle;margin-right:6px;">
          <!-- Smart Bus--> </div> 
    <?php $current = uri_string(); foreach ($links as $l): ?>
        <a href="<?= site_url($l['url']) ?>"
           class="<?= strpos($current, $l['url']) === 0 ? 'active' : '' ?>">
            <i class="bi bi-<?= $l['icon'] ?>"></i><?= esc($l['label']) ?>
        </a>
    <?php endforeach; ?>
    <a href="<?= site_url('logout') ?>" style="margin-top:20px;">
        <i class="bi bi-box-arrow-right"></i>Log out
    </a>
</nav>

<div class="main">
    <div class="topbar">
        <h5 class="mb-0"><?= esc($title) ?></h5>
        <div>
            <span class="text-muted me-2">
                <i class="bi bi-person-circle"></i> <?= esc($userName) ?>
            </span>
            <span class="badge bg-secondary"><?= esc(ucfirst($role)) ?></span>
        </div>
    </div>

    <?php if ($flash): ?>
        <div class="alert alert-<?= esc($flash['type'] ?? 'info') ?> alert-dismissible fade show">
            <?= esc($flash['msg'] ?? '') ?>
            <button type="button" class="btn-close" data-bs-dismiss="alert"></button>
        </div>
    <?php endif; ?>

    <?= $content ?? '' ?>
</div>

<script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.2/dist/js/bootstrap.bundle.min.js"></script>
</body>
</html>
