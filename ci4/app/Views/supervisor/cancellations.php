<div class="card">
    <div class="card-header bg-white">
        <strong><i class="bi bi-x-circle"></i> Cancellation Requests</strong>
    </div>
    <div class="table-responsive">
        <table class="table table-hover mb-0">
            <thead class="table-light">
                <tr>
                    <th>ID</th><th>Driver</th><th>Trip</th>
                    <th>Date</th><th>Time</th>
                    <th>Reason</th><th>Status</th><th>Action</th>
                </tr>
            </thead>
            <tbody>
            <?php if (empty($cancels)): ?>
                <tr><td colspan="8" class="text-center text-muted py-4">
                    No cancellation requests yet.
                </td></tr>
            <?php else: foreach ($cancels as $c): ?>
                <tr>
                    <td>#<?= $c['cancel_id'] ?></td>
                    <td><?= esc($c['driver_name']) ?></td>
                    <td>
                        <?= esc($c['route_name']) ?>
                        <small class="d-block text-muted"><?= esc($c['plate_number']) ?></small>
                    </td>
                    <td><?= esc($c['schedule_date']) ?></td>
                    <td><?= esc($c['expected_start']) ?> – <?= esc($c['expected_end']) ?></td>
                    <td><?= esc($c['reason'] ?? '—') ?></td>
                    <td>
                        <?php
                        $colors = ['Pending'=>'warning','Approved'=>'success','Rejected'=>'danger'];
                        $cls = $colors[$c['status']] ?? 'secondary';
                        ?>
                        <span class="badge bg-<?= $cls ?>"><?= esc($c['status']) ?></span>
                    </td>
                    <td>
                        <?php if ($c['status'] === 'Pending'): ?>
                            <form method="post"
                                  action="<?= site_url('supervisor/cancellations/review/' . $c['cancel_id']) ?>"
                                  class="d-inline">
                                <?= csrf_field() ?>
                                <button name="decision" value="Approved"
                                        class="btn btn-sm btn-success"
                                        onclick="return confirm('Approve cancellation? Trip will become unassigned.')">
                                    <i class="bi bi-check"></i>
                                </button>
                                <button name="decision" value="Rejected"
                                        class="btn btn-sm btn-danger">
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
