<div class="row g-3">
    <!-- Form -->
    <div class="col-md-4">
        <div class="card">
            <div class="card-header bg-white"><strong>Add Driver</strong></div>
            <div class="card-body">
                <form method="post" action="<?= site_url('admin/drivers/store') ?>">
                    <?= csrf_field() ?>
                    <div class="mb-2">
                        <label class="form-label">Full name</label>
                        <input name="full_name" class="form-control" required>
                    </div>
                    <div class="mb-2">
                        <label class="form-label">Email</label>
                        <input type="email" name="email" class="form-control" required>
                    </div>
                    <div class="mb-2">
                        <label class="form-label">Phone</label>
                        <input name="phone" class="form-control">
                    </div>
                    <div class="mb-3">
                        <label class="form-label">Initial password</label>
                        <input type="password" name="password" class="form-control" required minlength="6">
                        <small class="text-muted">Driver should change after first login.</small>
                    </div>
                    <button class="btn btn-primary w-100">
                        <i class="bi bi-plus-circle"></i> Add Driver
                    </button>
                </form>
            </div>
        </div>
    </div>

    <!-- List -->
    <div class="col-md-8">
        <div class="card">
            <div class="card-header bg-white"><strong>Existing Drivers</strong></div>
            <div class="table-responsive">
                <table class="table table-hover mb-0">
                    <thead class="table-light">
                        <tr><th>ID</th><th>Name</th><th>Email</th><th>Phone</th><th>Status</th><th></th></tr>
                    </thead>
                    <tbody>
                    <?php foreach ($drivers as $d): ?>
                        <tr>
                            <td>#<?= $d['driver_id'] ?></td>
                            <td><?= esc($d['full_name']) ?></td>
                            <td><?= esc($d['email']) ?></td>
                            <td><?= esc($d['phone'] ?? '-') ?></td>
                            <td>
                                <span class="badge bg-<?= $d['status']==='active' ? 'success':'secondary' ?>">
                                    <?= esc($d['status']) ?>
                                </span>
                            </td>
                            <td>
                                <?php if ($d['status']==='active'): ?>
                                    <a href="<?= site_url('admin/drivers/delete/' . $d['driver_id']) ?>"
                                       class="btn btn-sm btn-outline-danger"
                                       onclick="return confirm('Deactivate this driver?')">
                                        <i class="bi bi-person-x"></i>
                                    </a>
                                <?php endif; ?>
                            </td>
                        </tr>
                    <?php endforeach; ?>
                    </tbody>
                </table>
            </div>
        </div>
    </div>
</div>
