<div class="card mb-3">
    <div class="card-body d-flex justify-content-between align-items-center">
        <div>
            <i class="bi bi-broadcast text-success"></i>
            <strong>Live Fleet Status</strong>
            <small class="text-muted ms-2">Auto-refreshes every 30 seconds</small>
        </div>
        <button onclick="location.reload()" class="btn btn-sm btn-outline-primary">
            <i class="bi bi-arrow-clockwise"></i> Refresh now
        </button>
    </div>
</div>

<div class="row g-3">
<?php if (empty($fleet)): ?>
    <div class="col-12">
        <div class="alert alert-info">No buses registered yet.</div>
    </div>
<?php else: foreach ($fleet as $f): ?>
    <?php
    // Pick a card border colour based on what the bus is doing right now.
    $border = 'secondary';
    if (!empty($f['job_status'])) {
        $border = match($f['job_status']) {
            'In-Progress' => 'warning',
            'Pending'     => 'info',
            'Completed'   => 'success',
            default       => 'secondary',
        };
    } elseif ($f['bus_status'] === 'maintenance') {
        $border = 'danger';
    }
    ?>
    <div class="col-md-6 col-lg-4">
        <div class="card border-start border-4 border-<?= $border ?>">
            <div class="card-body">
                <div class="d-flex justify-content-between">
                    <h5 class="mb-0">
                        <i class="bi bi-bus-front"></i> <?= esc($f['plate_number']) ?>
                    </h5>
                    <?php if (!empty($f['job_status'])): ?>
                        <span class="badge bg-<?= $border ?>"><?= esc($f['job_status']) ?></span>
                    <?php else: ?>
                        <span class="badge bg-<?= $f['bus_status']==='maintenance' ? 'danger' : 'secondary' ?>">
                            <?= esc(ucfirst($f['bus_status'])) ?>
                        </span>
                    <?php endif; ?>
                </div>
                <small class="text-muted d-block mb-2">MAC: <?= esc($f['mac_address']) ?></small>

                <?php if (!empty($f['driver_name'])): ?>
                    <div><i class="bi bi-person"></i> <?= esc($f['driver_name']) ?></div>
                    <div><i class="bi bi-signpost"></i> <?= esc($f['route_name']) ?></div>
                    <small class="text-muted">
                        <?= esc($f['origin']) ?> → <?= esc($f['destination']) ?>
                    </small>
                    <hr class="my-2">
                    <div class="row small">
                        <div class="col-6"><strong>Expected:</strong><br><?= esc($f['expected_start']) ?> – <?= esc($f['expected_end']) ?></div>
                        <div class="col-6"><strong>Actual:</strong><br>
                            <?= esc($f['actual_start'] ? substr($f['actual_start'],11,5) : '—') ?> –
                            <?= esc($f['actual_end']   ? substr($f['actual_end'],  11,5) : '—') ?>
                        </div>
                    </div>
                    <?php if ($f['is_synced'] !== null && (int)$f['is_synced'] === 0): ?>
                        <div class="alert alert-warning p-2 mt-2 mb-0 small">
                            <i class="bi bi-cloud-arrow-up"></i> Pending sync from device
                        </div>
                    <?php endif; ?>
                <?php else: ?>
                    <div class="text-muted small">No active assignment.</div>
                <?php endif; ?>
            </div>
        </div>
    </div>
<?php endforeach; endif; ?>
</div>

<script>
    // Auto-refresh every 30s for that "live" feel.
    setTimeout(() => location.reload(), 30000);
</script>
