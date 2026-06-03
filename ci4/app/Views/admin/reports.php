<!-- Date range filter -->
<div class="card mb-3">
    <div class="card-body">
        <form method="get" class="row g-2 align-items-end mb-0">
            <div class="col-md-3">
                <label class="form-label small">From</label>
                <input type="date" name="from" class="form-control form-control-sm"
                       value="<?= esc($from) ?>">
            </div>
            <div class="col-md-3">
                <label class="form-label small">To</label>
                <input type="date" name="to" class="form-control form-control-sm"
                       value="<?= esc($to) ?>">
            </div>
            <div class="col-md-3">
                <button class="btn btn-sm btn-primary">
                    <i class="bi bi-funnel"></i> Apply Filter
                </button>
                <button type="button" onclick="window.print()" class="btn btn-sm btn-outline-secondary">
                    <i class="bi bi-printer"></i> Print
                </button>
            </div>
        </form>
    </div>
</div>

<!-- Trip completion -->
<div class="card mb-3">
    <div class="card-header bg-white">
        <strong>Trip Completion by Day</strong>
        <small class="text-muted ms-2"><?= esc($from) ?> to <?= esc($to) ?></small>
    </div>
    <div class="table-responsive">
        <table class="table table-hover mb-0">
            <thead class="table-light">
                <tr>
                    <th>Date</th><th>Total</th><th>Completed</th>
                    <th>In Progress</th><th>Pending</th><th>Cancelled</th><th>Completion %</th>
                </tr>
            </thead>
            <tbody>
            <?php if (empty($dailyTrips)): ?>
                <tr><td colspan="7" class="text-center text-muted py-3">No data in range.</td></tr>
            <?php else: foreach ($dailyTrips as $d): ?>
                <?php $pct = $d['total'] > 0 ? round(($d['completed']/$d['total'])*100) : 0; ?>
                <tr>
                    <td><?= esc($d['schedule_date']) ?></td>
                    <td><?= $d['total'] ?></td>
                    <td class="text-success"><?= $d['completed'] ?></td>
                    <td class="text-warning"><?= $d['in_progress'] ?></td>
                    <td class="text-muted"><?= $d['pending'] ?></td>
                    <td class="text-danger"><?= $d['cancelled'] ?></td>
                    <td>
                        <div class="progress" style="height:18px;">
                            <div class="progress-bar bg-success" style="width:<?= $pct ?>%">
                                <?= $pct ?>%
                            </div>
                        </div>
                    </td>
                </tr>
            <?php endforeach; endif; ?>
            </tbody>
        </table>
    </div>
</div>

<div class="row g-3">
    <!-- Overtime by driver -->
    <div class="col-md-8">
        <div class="card">
            <div class="card-header bg-white"><strong>Overtime by Driver</strong></div>
            <div class="table-responsive">
                <table class="table table-hover mb-0">
                    <thead class="table-light">
                        <tr><th>Driver</th><th>Requests</th><th>Total Minutes</th><th>Approved</th></tr>
                    </thead>
                    <tbody>
                    <?php if (empty($overtimeSummary)): ?>
                        <tr><td colspan="4" class="text-center text-muted py-3">No overtime in range.</td></tr>
                    <?php else: foreach ($overtimeSummary as $o): ?>
                        <tr>
                            <td><?= esc($o['driver_name']) ?></td>
                            <td><?= (int)$o['total_requests'] ?></td>
                            <td><strong><?= (int)$o['total_minutes'] ?> min</strong>
                                <small class="text-muted">(<?= round($o['total_minutes']/60, 1) ?>h)</small>
                            </td>
                            <td><?= (int)$o['approved_count'] ?></td>
                        </tr>
                    <?php endforeach; endif; ?>
                    </tbody>
                </table>
            </div>
        </div>
    </div>

    <!-- Leave summary -->
    <div class="col-md-4">
        <div class="card h-100">
            <div class="card-header bg-white"><strong>Leave Applications</strong></div>
            <div class="card-body">
                <?php if (empty($leaveSummary)): ?>
                    <p class="text-muted text-center py-3 mb-0">None in range.</p>
                <?php else: foreach ($leaveSummary as $l): ?>
                    <?php
                    $c = ['Pending'=>'warning','Approved'=>'success','Rejected'=>'danger'];
                    $cls = $c[$l['status']] ?? 'secondary';
                    ?>
                    <div class="d-flex justify-content-between align-items-center mb-2">
                        <span class="badge bg-<?= $cls ?>"><?= esc($l['status']) ?></span>
                        <strong class="fs-4"><?= (int)$l['cnt'] ?></strong>
                    </div>
                <?php endforeach; endif; ?>
            </div>
        </div>
    </div>
</div>
