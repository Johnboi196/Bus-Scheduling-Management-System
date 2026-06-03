<div class="row g-3 mb-4">
    <div class="col-md-3">
        <div class="card stat-card p-3">
            <div class="text-muted small">Today's Trips</div>
            <div class="display-6"><?= $stats['today_total'] ?></div>
        </div>
    </div>
    <div class="col-md-3">
        <div class="card stat-card ok p-3">
            <div class="text-muted small">Completed</div>
            <div class="display-6"><?= $stats['completed'] ?></div>
        </div>
    </div>
    <div class="col-md-3">
        <div class="card stat-card warn p-3">
            <div class="text-muted small">In Progress</div>
            <div class="display-6"><?= $stats['in_progress'] ?></div>
        </div>
    </div>
    <div class="col-md-3">
        <div class="card stat-card danger p-3">
            <div class="text-muted small">Pending Reviews</div>
            <div class="display-6"><?= $stats['pending_ot'] + $stats['pending_leave'] ?></div>
            <small class="text-muted">
                <?= $stats['pending_ot'] ?> overtime · <?= $stats['pending_leave'] ?> leave
            </small>
        </div>
    </div>
</div>

<div class="card">
    <div class="card-header bg-white d-flex justify-content-between align-items-center">
        <strong>Today's Schedules</strong>
        <a href="<?= site_url('supervisor/schedules/create') ?>" class="btn btn-primary btn-sm">
            <i class="bi bi-plus-circle"></i> New Schedule
        </a>
    </div>
    <div class="table-responsive">
        <table class="table table-hover mb-0">
            <thead class="table-light">
                <tr>
                    <th>Time</th><th>Driver</th><th>Bus</th><th>Route</th>
                    <th>Status</th><th>Synced</th>
                </tr>
            </thead>
            <tbody>
            <?php if (empty($todaySchedules)): ?>
                <tr><td colspan="6" class="text-center text-muted py-4">No schedules for today.</td></tr>
            <?php else: foreach ($todaySchedules as $s): ?>
                <tr>
                    <td><?= esc($s['expected_start']) ?> – <?= esc($s['expected_end']) ?></td>
                    <td><?= esc($s['driver_name']) ?></td>
                    <td><?= esc($s['plate_number']) ?></td>
                    <td><?= esc($s['route_name']) ?></td>
                    <td>
                        <?php
                        $colors = [
                            'Pending'=>'secondary','In-Progress'=>'warning',
                            'Completed'=>'success','Cancelled'=>'dark'
                        ];
                        $c = $colors[$s['job_status']] ?? 'secondary';
                        ?>
                        <span class="badge bg-<?= $c ?>"><?= esc($s['job_status']) ?></span>
                    </td>
                    <td>
                        <?php if ($s['is_synced']): ?>
                            <i class="bi bi-cloud-check text-success" title="Synced"></i>
                        <?php else: ?>
                            <i class="bi bi-cloud-arrow-up text-warning" title="Pending sync"></i>
                        <?php endif; ?>
                    </td>
                </tr>
            <?php endforeach; endif; ?>
            </tbody>
        </table>
    </div>
</div>
