<div class="card">
    <div class="card-header bg-white"><strong>Leave Applications</strong></div>
    <div class="table-responsive">
        <table class="table table-hover mb-0">
            <thead class="table-light">
                <tr>
                    <th>ID</th><th>Driver</th><th>From</th><th>To</th>
                    <th>Days</th><th>Reason</th><th>Status</th><th>Action</th>
                </tr>
            </thead>
            <tbody>
            <?php if (empty($leaves)): ?>
                <tr><td colspan="8" class="text-center text-muted py-4">
                    No leave applications yet.
                </td></tr>
            <?php else: foreach ($leaves as $l): ?>
                <?php
                $days = (int)((strtotime($l['end_date']) - strtotime($l['start_date'])) / 86400) + 1;
                ?>
                <tr>
                    <td>#<?= $l['leave_id'] ?></td>
                    <td><?= esc($l['driver_name']) ?></td>
                    <td><?= esc($l['start_date']) ?></td>
                    <td><?= esc($l['end_date']) ?></td>
                    <td><?= $days ?></td>
                    <td><?= esc($l['reason'] ?? '') ?></td>
                    <td>
                        <?php
                        $c = ['Pending'=>'warning','Approved'=>'success','Rejected'=>'danger'];
                        $cls = $c[$l['status']] ?? 'secondary';
                        ?>
                        <span class="badge bg-<?= $cls ?>"><?= esc($l['status']) ?></span>
                    </td>
                    <td>
                        <?php if ($l['status'] === 'Pending'): ?>
                            <form method="post" action="<?= site_url('supervisor/leave/review/' . $l['leave_id']) ?>" class="d-inline">
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
