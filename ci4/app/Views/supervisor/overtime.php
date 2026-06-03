<div class="card">
    <div class="card-header bg-white"><strong>Overtime Requests</strong></div>
    <div class="table-responsive">
        <table class="table table-hover mb-0">
            <thead class="table-light">
                <tr>
                    <th>ID</th><th>Driver</th><th>Route</th><th>Date</th>
                    <th>Expected End</th><th>Actual End</th>
                    <th>Extra (min)</th><th>Reason</th><th>Status</th><th>Action</th>
                </tr>
            </thead>
            <tbody>
            <?php if (empty($overtime)): ?>
                <tr><td colspan="10" class="text-center text-muted py-4">
                    No overtime requests yet.
                </td></tr>
            <?php else: foreach ($overtime as $o): ?>
                <tr>
                    <td>#<?= $o['overtime_id'] ?></td>
                    <td><?= esc($o['driver_name']) ?></td>
                    <td><?= esc($o['route_name']) ?></td>
                    <td><?= esc($o['schedule_date']) ?></td>
                    <td><?= esc($o['expected_end']) ?></td>
                    <td><?= esc($o['actual_end'] ?? '-') ?></td>
                    <td><strong><?= (int)$o['extra_minutes'] ?></strong></td>
                    <td><?= esc($o['reason'] ?? '') ?></td>
                    <td>
                        <?php
                        $c = ['Pending'=>'warning','Approved'=>'success','Rejected'=>'danger'];
                        $cls = $c[$o['status']] ?? 'secondary';
                        ?>
                        <span class="badge bg-<?= $cls ?>"><?= esc($o['status']) ?></span>
                    </td>
                    <td>
                        <?php if ($o['status'] === 'Pending'): ?>
                            <form method="post" action="<?= site_url('supervisor/overtime/review/' . $o['overtime_id']) ?>" class="d-inline">
                                <?= csrf_field() ?>
                                <button name="decision" value="Approved" class="btn btn-sm btn-success">
                                    <i class="bi bi-check"></i>
                                </button>
                                <button name="decision" value="Rejected" class="btn btn-sm btn-danger">
                                    <i class="bi bi-x"></i>
                                </button>
                            </form>
                        <?php else: ?>
                            <small class="text-muted">Reviewed</small>
                        <?php endif; ?>
                    </td>
                </tr>
            <?php endforeach; endif; ?>
            </tbody>
        </table>
    </div>
</div>
