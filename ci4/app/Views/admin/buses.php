<div class="row g-3">
    <div class="col-md-4">
        <div class="card">
            <div class="card-header bg-white"><strong>Register Bus</strong></div>
            <div class="card-body">
                <form method="post" action="<?= site_url('admin/buses/store') ?>">
                    <?= csrf_field() ?>
                    <div class="mb-2">
                        <label class="form-label">Plate Number</label>
                        <input name="plate_number" class="form-control" required
                               placeholder="WXY1234" style="text-transform:uppercase">
                    </div>
                    <div class="mb-2">
                        <label class="form-label">MAC Address</label>
                        <input name="mac_address" class="form-control" required
                               placeholder="00:13:10:85:FE:01"
                               style="text-transform:uppercase">
                        <small class="text-muted">
                            The in-bus tablet's network MAC. Use the BSSID Android reports.
                        </small>
                    </div>
                    <div class="mb-3">
                        <label class="form-label">Status</label>
                        <select name="status" class="form-select">
                            <option value="available">Available</option>
                            <option value="in_service">In service</option>
                            <option value="maintenance">Maintenance</option>
                        </select>
                    </div>
                    <button class="btn btn-primary w-100">
                        <i class="bi bi-plus-circle"></i> Register Bus
                    </button>
                </form>
            </div>
        </div>
    </div>

    <div class="col-md-8">
        <div class="card">
            <div class="card-header bg-white"><strong>Fleet</strong></div>
            <div class="table-responsive">
                <table class="table table-hover mb-0">
                    <thead class="table-light">
                        <tr>
                            <th>ID</th><th>Plate</th><th>MAC Address</th>
                            <th>Status</th><th></th>
                        </tr>
                    </thead>
                    <tbody>
                    <?php if (empty($buses)): ?>
                        <tr><td colspan="5" class="text-center text-muted py-4">
                            No buses registered yet.
                        </td></tr>
                    <?php else: foreach ($buses as $b): ?>
                        <tr>
                            <td>#<?= $b['bus_id'] ?></td>
                            <td><strong><?= esc($b['plate_number']) ?></strong></td>
                            <td>
                                <code class="small"><?= esc($b['mac_address']) ?></code>
                            </td>
                            <td>
                                <?php
                                $c = ['available'=>'success','in_service'=>'primary','maintenance'=>'danger'];
                                $cls = $c[$b['status']] ?? 'secondary';
                                ?>
                                <span class="badge bg-<?= $cls ?>">
                                    <?= esc(str_replace('_',' ', $b['status'])) ?>
                                </span>
                            </td>
                            <td>
                                <a href="<?= site_url('admin/buses/delete/' . $b['bus_id']) ?>"
                                   class="btn btn-sm btn-outline-danger"
                                   onclick="return confirm('Delete this bus?')">
                                    <i class="bi bi-trash"></i>
                                </a>
                            </td>
                        </tr>
                    <?php endforeach; endif; ?>
                    </tbody>
                </table>
            </div>
        </div>
    </div>
</div>
