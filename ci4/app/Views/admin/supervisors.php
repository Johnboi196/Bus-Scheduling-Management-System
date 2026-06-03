<div class="row g-3">
    <div class="col-md-4">
        <div class="card">
            <div class="card-header bg-white"><strong>Add Supervisor</strong></div>
            <div class="card-body">
                <form method="post" action="<?= site_url('admin/supervisors/store') ?>">
                    <?= csrf_field() ?>
                    <div class="mb-2">
                        <label class="form-label">Full name</label>
                        <input name="full_name" class="form-control" required>
                    </div>
                    <div class="mb-2">
                        <label class="form-label">Employee ID</label>
                        <input name="employee_id" class="form-control" required>
                    </div>
                    <div class="mb-2">
                        <label class="form-label">Email</label>
                        <input type="email" name="email" class="form-control" required>
                    </div>
                    <div class="mb-3">
                        <label class="form-label">Initial password</label>
                        <input type="password" name="password" class="form-control" required minlength="6">
                    </div>
                    <button class="btn btn-primary w-100">
                        <i class="bi bi-plus-circle"></i> Add Supervisor
                    </button>
                </form>
            </div>
        </div>
    </div>

    <div class="col-md-8">
        <div class="card">
            <div class="card-header bg-white"><strong>Existing Supervisors</strong></div>
            <div class="table-responsive">
                <table class="table table-hover mb-0">
                    <thead class="table-light">
                        <tr><th>ID</th><th>Employee ID</th><th>Name</th><th>Email</th><th></th></tr>
                    </thead>
                    <tbody>
                    <?php foreach ($supervisors as $s): ?>
                        <tr>
                            <td>#<?= $s['supervisor_id'] ?></td>
                            <td><code><?= esc($s['employee_id']) ?></code></td>
                            <td><?= esc($s['full_name']) ?></td>
                            <td><?= esc($s['email']) ?></td>
                            <td>
                                <a href="<?= site_url('admin/supervisors/delete/' . $s['supervisor_id']) ?>"
                                   class="btn btn-sm btn-outline-danger"
                                   onclick="return confirm('Delete this supervisor?')">
                                    <i class="bi bi-trash"></i>
                                </a>
                            </td>
                        </tr>
                    <?php endforeach; ?>
                    </tbody>
                </table>
            </div>
        </div>
    </div>
</div>
