<div class="card">
    <div class="card-header bg-white">
        <strong><i class="bi bi-inbox"></i> Unassigned Trips</strong>
        <small class="text-muted">Trips with no driver yet (today and future).</small>
    </div>
    <div class="table-responsive">
        <table class="table table-hover mb-0">
            <thead class="table-light">
                <tr>
                    <th>ID</th><th>Date</th><th>Time</th><th>Route</th>
                    <th>Bus</th><th style="width:300px">Assign to Driver</th>
                </tr>
            </thead>
            <tbody>
            <?php if (empty($unassigned)): ?>
                <tr><td colspan="6" class="text-center text-muted py-4">
                    No unassigned trips. Good coverage!
                </td></tr>
            <?php else: foreach ($unassigned as $u): ?>
                <tr>
                    <td>#<?= $u['schedule_id'] ?></td>
                    <td><?= esc($u['schedule_date']) ?></td>
                    <td><?= esc($u['expected_start']) ?> – <?= esc($u['expected_end']) ?></td>
                    <td>
                        <?= esc($u['route_name']) ?>
                        <small class="d-block text-muted">
                            <?= esc($u['origin']) ?> → <?= esc($u['destination']) ?>
                        </small>
                    </td>
                    <td><?= esc($u['plate_number']) ?></td>
                    <td>
                        <form method="post"
                              action="<?= site_url('supervisor/unassigned/assign/' . $u['schedule_id']) ?>"
                              class="d-flex gap-2">
                            <?= csrf_field() ?>
                            <select name="driver_id" class="form-select form-select-sm" required>
                                <option value="">-- pick driver --</option>
                                <?php foreach ($drivers as $d): ?>
                                    <option value="<?= $d['driver_id'] ?>">
                                        <?= esc($d['full_name']) ?>
                                    </option>
                                <?php endforeach; ?>
                            </select>
                            <button class="btn btn-sm btn-primary" type="submit">
                                <i class="bi bi-person-plus"></i>
                            </button>
                        </form>
                    </td>
                </tr>
            <?php endforeach; endif; ?>
            </tbody>
        </table>
    </div>
</div>
