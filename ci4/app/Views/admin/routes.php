<div class="row g-3">
    <div class="col-md-4">
        <div class="card">
            <div class="card-header bg-white"><strong>Add Route</strong></div>
            <div class="card-body">
                <form method="post" action="<?= site_url('admin/routes/store') ?>">
                    <?= csrf_field() ?>
                    <div class="mb-2">
                        <label class="form-label">Route Name</label>
                        <input name="route_name" class="form-control" required
                               placeholder="KL-PJ Express">
                    </div>
                    <div class="mb-2">
                        <label class="form-label">Origin</label>
                        <input name="origin" class="form-control" required placeholder="Kuala Lumpur">
                    </div>
                    <div class="mb-2">
                        <label class="form-label">Destination</label>
                        <input name="destination" class="form-control" required placeholder="Petaling Jaya">
                    </div>
                    <div class="mb-3">
                        <label class="form-label">Distance (km)</label>
                        <input type="number" step="0.1" name="distance_km" class="form-control"
                               placeholder="15.5">
                    </div>
                    <button class="btn btn-primary w-100">
                        <i class="bi bi-plus-circle"></i> Add Route
                    </button>
                </form>
            </div>
        </div>
    </div>

    <div class="col-md-8">
        <div class="card">
            <div class="card-header bg-white"><strong>Routes</strong></div>
            <div class="table-responsive">
                <table class="table table-hover mb-0">
                    <thead class="table-light">
                        <tr><th>ID</th><th>Name</th><th>Origin → Destination</th><th>Distance</th><th></th></tr>
                    </thead>
                    <tbody>
                    <?php foreach ($routes as $r): ?>
                        <tr>
                            <td>#<?= $r['route_id'] ?></td>
                            <td><strong><?= esc($r['route_name']) ?></strong></td>
                            <td><?= esc($r['origin']) ?> → <?= esc($r['destination']) ?></td>
                            <td><?= $r['distance_km'] ? number_format($r['distance_km'],1) . ' km' : '-' ?></td>
                            <td>
                                <a href="<?= site_url('admin/routes/delete/' . $r['route_id']) ?>"
                                   class="btn btn-sm btn-outline-danger"
                                   onclick="return confirm('Delete this route?')">
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
