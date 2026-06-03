<!doctype html>
<html lang="en">
<head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>Login · Smart Bus</title>
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.2/dist/css/bootstrap.min.css" rel="stylesheet">
    <link href="https://cdn.jsdelivr.net/npm/bootstrap-icons@1.11.1/font/bootstrap-icons.min.css" rel="stylesheet">
    <style>
        body {
            background: linear-gradient(135deg, #DC1E5E 0%, #C9942D 100%);
            min-height: 100vh; display:flex; align-items:center; justify-content:center;
        }
        .login-card { width: 100%; max-width: 420px; }
    </style>
</head>
<body>
<div class="login-card">
    <div class="card shadow-lg">
        <div class="card-body p-5">
            <div class="text-center mb-4">
                <img src="<?= base_url('assets/img/logo.png') ?>"
     alt="Smart Bus"
     style="height:64px;width:auto;">
                <!-- <h3 class="mt-2">Smart Bus</h3> -->
                <p class="text-muted">Staff Login</p>
            </div>

            <?php $error = session()->getFlashdata('error'); if ($error): ?>
                <div class="alert alert-danger"><?= esc($error) ?></div>
            <?php endif; ?>

            <form method="post" action="<?= site_url('login') ?>">
                <?= csrf_field() ?>

                <div class="mb-3">
                    <label class="form-label">Role</label>
                    <select name="role" class="form-select" required>
                        <option value="supervisor">Supervisor</option>
                        <option value="admin">Admin</option>
                    </select>
                </div>

                <div class="mb-3">
                    <label class="form-label">Employee ID</label>
                    <div class="input-group">
                        <span class="input-group-text"><i class="bi bi-person-badge"></i></span>
                        <input type="text" name="employee_id" class="form-control"
                               value="<?= esc(old('employee_id')) ?>"
                               placeholder="e.g. SUP001 or ADM001"
                               required autofocus
                               style="text-transform:uppercase">
                    </div>
                </div>

                <div class="mb-3">
                    <label class="form-label">Password</label>
                    <div class="input-group">
                        <span class="input-group-text"><i class="bi bi-lock"></i></span>
                        <input type="password" name="password" class="form-control" required>
                    </div>
                </div>

                <button class="btn btn-primary w-100">
                    <i class="bi bi-box-arrow-in-right"></i> Log in
                </button>
            </form>

            <hr class="my-4">
            <small class="text-muted d-block text-center">
                Supervisor: <code>SUP001</code> · Admin: <code>ADM001</code><br>
                Password: <code>password123</code>
            </small>
        </div>
    </div>
</div>
</body>
</html>
