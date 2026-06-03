<div class="alert alert-info d-flex align-items-center mb-3">
    <i class="bi bi-info-circle me-2"></i>
    <div>
        Approving one volunteer for a trip automatically rejects all other
        pending volunteers for the same trip.
    </div>
</div>

<div class="card">
    <div class="card-header bg-white">
        <strong><i class="bi bi-hand-thumbs-up"></i> Volunteer Requests</strong>
    </div>
    <div class="table-responsive">
        <table class="table table-hover mb-0">
            <thead class="table-light">
                <tr>
                    <th>ID</th><th>Volunteer</th><th>Trip</th>
                    <th>Date</th><th>Time</th>
                    <th>Note</th><th>Status</th><th>Action</th>
                </tr>
            </thead>
            <tbody>
            <?php if (empty($volunteers)): ?>
                <tr><td colspan="8" class="text-center text-muted py-4">
                    No volunteer requests yet.
                </td></tr>
            <?php else: foreach ($volunteers as $v): ?>
                <tr>
                    <td>#<?= $v['volunteer_id'] ?></td>
                    <td><?= esc($v['driver_name']) ?></td>
                    <td>
                        <?= esc($v['route_name']) ?>
                        <small class="d-block text-muted"><?= esc($v['plate_number']) ?></small>
                        <?php if (!empty($v['current_driver_id'])): ?>
                            <small class="text-warning">
                                <i class="bi bi-exclamation-triangle"></i>
                                Trip is already assigned
                            </small>
                        <?php endif; ?>
                    </td>
                    <td><?= esc($v['schedule_date']) ?></td>
                    <td><?= esc($v['expected_start']) ?> – <?= esc($v['expected_end']) ?></td>
                    <td><?= esc($v['note'] ?? '—') ?></td>
                    <td>
                        <?php
                        $colors = [
                            'Pending'=>'warning','Approved'=>'success',
                            'Rejected'=>'danger','Auto-Rejected'=>'secondary'
                        ];
                        $cls = $colors[$v['status']] ?? 'secondary';
                        ?>
                        <span class="badge bg-<?= $cls ?>"><?= esc($v['status']) ?></span>
                    </td>
                    <td>
                        <?php if ($v['status'] === 'Pending' && empty($v['current_driver_id'])): ?>
                            <form method="post"
                                  action="<?= site_url('supervisor/volunteers/review/' . $v['volunteer_id']) ?>"
                                  class="d-inline">
                                <?= csrf_field() ?>
                                <button name="decision" value="Approved"
                                        class="btn btn-sm btn-success">
                                    <i class="bi bi-check"></i>
                                </button>
                                <button name="decision" value="Rejected"
                                        class="btn btn-sm btn-danger">
                                    <i class="bi bi-x"></i>
                                </button>
                            </form>
                        <?php else: ?>
                            <small class="text-muted">
                                <?= $v['status'] === 'Pending' ? 'Trip taken' : 'Reviewed' ?>
                            </small>
                        <?php endif; ?>
                    </td>
                </tr>
            <?php endforeach; endif; ?>
            </tbody>
        </table>
    </div>
</div>
