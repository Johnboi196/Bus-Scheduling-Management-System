<div class="card mb-3">
    <div class="card-body d-flex justify-content-between align-items-center flex-wrap gap-2">
        <form method="get" action="<?= site_url('supervisor/schedules') ?>"
              class="d-flex gap-2 align-items-center mb-0">
            <label class="mb-0">Filter by date:</label>
            <input type="date" name="date" class="form-control form-control-sm"
                   style="width:170px" value="<?= esc($filterDate ?? '') ?>">
            <button class="btn btn-sm btn-outline-primary">
                <i class="bi bi-funnel"></i> Apply
            </button>
            <?php if (!empty($filterDate)): ?>
                <a href="<?= site_url('supervisor/schedules') ?>"
                   class="btn btn-sm btn-outline-secondary">
                    <i class="bi bi-x-circle"></i> Show all
                </a>
            <?php endif; ?>
        </form>
        <div>
            <a href="<?= site_url('supervisor/schedules/create') ?>" class="btn btn-primary btn-sm">
                <i class="bi bi-plus-circle"></i> New Schedule
            </a>
            <button onclick="window.print()" class="btn btn-outline-secondary btn-sm">
                <i class="bi bi-printer"></i> Print
            </button>
        </div>
    </div>
</div>

<?php if (!empty($filterDate)): ?>
    <div class="alert alert-info py-2 mb-3">
        <i class="bi bi-funnel-fill"></i>
        Showing trips for <strong><?= esc($filterDate) ?></strong>
        (<?= count($schedules) ?> result<?= count($schedules) === 1 ? '' : 's' ?>).
    </div>
<?php else: ?>
    <div class="text-muted small mb-2">
        Showing <strong>all schedules</strong> (<?= count($schedules) ?>).
        Use the date filter above to narrow down.
    </div>
<?php endif; ?>

<div class="card">
    <div class="table-responsive">
        <table class="table table-hover mb-0">
            <thead class="table-light">
                <tr>
                    <th>ID</th>
                    <th>Date</th>
                    <th>Time</th>
                    <th>Driver</th>
                    <th>Bus</th>
                    <th>Route</th>
                    <th>Status</th>
                    <th>Actions</th>
                </tr>
            </thead>
            <tbody>
            <?php if (empty($schedules)): ?>
                <tr><td colspan="8" class="text-center text-muted py-4">
                    <?php if (!empty($filterDate)): ?>
                        No schedules for <?= esc($filterDate) ?>.
                    <?php else: ?>
                        No schedules in the system yet.
                    <?php endif; ?>
                </td></tr>
            <?php else: foreach ($schedules as $s): ?>
                <tr>
                    <td>#<?= $s['schedule_id'] ?></td>
                    <td>
                        <small><?= esc($s['schedule_date']) ?></small>
                    </td>
                    <td><?= esc($s['expected_start']) ?> – <?= esc($s['expected_end']) ?></td>
                    <td>
                        <?php if (!empty($s['driver_name'])): ?>
                            <?= esc($s['driver_name']) ?>
                        <?php else: ?>
                            <span class="badge bg-warning text-dark">
                                <i class="bi bi-person-x"></i> Unassigned
                            </span>
                        <?php endif; ?>
                    </td>
                    <td><?= esc($s['plate_number']) ?></td>
                    <td><?= esc($s['route_name']) ?>
                        <small class="d-block text-muted">
                            <?= esc($s['origin']) ?> → <?= esc($s['destination']) ?>
                        </small>
                    </td>
                    <td>
                        <?php
                        $colors = [
                            'Pending'    => 'secondary',
                            'In-Progress'=> 'warning',
                            'Completed'  => 'success',
                            'Cancelled'  => 'dark',
                        ];
                        $c = $colors[$s['job_status']] ?? 'secondary';
                        ?>
                        <span class="badge bg-<?= $c ?>"><?= esc($s['job_status']) ?></span>
                    </td>
                    <td>
                        <a href="<?= site_url('supervisor/schedules/edit/' . $s['schedule_id']) ?>"
                           class="btn btn-sm btn-outline-primary">
                            <i class="bi bi-pencil"></i>
                        </a>
                        <a href="<?= site_url('supervisor/schedules/delete/' . $s['schedule_id']) ?>"
                           class="btn btn-sm btn-outline-danger"
                           onclick="return confirm('Delete this schedule?')">
                            <i class="bi bi-trash"></i>
                        </a>
                    </td>
                </tr>
            <?php endforeach; endif; ?>
            </tbody>
        </table>
    </div>
</div>
