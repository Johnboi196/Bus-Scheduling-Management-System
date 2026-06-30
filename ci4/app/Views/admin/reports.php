<style>
/* PRINT STYLES — hide sidebar/topbar when printing */
@media print {
    body { background: #fff !important; }
    .sidebar, .topbar, .no-print, .btn, .pagination,
    nav, header, footer { display: none !important; }
    .main { margin-left: 0 !important; padding: 0 !important; }
    .card { box-shadow: none !important; border: 1px solid #ccc !important; }
    .table { font-size: 11px !important; }
    .print-header { display: block !important; }
    @page { margin: 1.5cm; size: A4 landscape; }
}
.print-header { display: none; }

.score-badge {
    font-size: 1.1rem;
    font-weight: 600;
    padding: 0.4rem 0.7rem;
    border-radius: 4px;
    display: inline-block;
    min-width: 70px;
    text-align: center;
}
.score-excellent { background: #d1e7dd; color: #0a3622; }
.score-good      { background: #cfe2ff; color: #052c65; }
.score-fair      { background: #fff3cd; color: #664d03; }
.score-poor      { background: #f8d7da; color: #58151c; }
.score-nodata { background: #e9ecef; color: #6c757d; }

.metric-cell { font-size: 0.85rem; color: #555; }
.metric-bar {
    display: inline-block; width: 50px; height: 6px;
    background: #e0e0e0; border-radius: 3px;
    overflow: hidden; vertical-align: middle; margin-right: 6px;
}
.metric-bar > span {
    display: block; height: 100%; background: #6B0E2F;
}
</style>

<!-- Print-only header -->
<div class="print-header" style="margin-bottom: 20px;">
    <h2 style="margin: 0;">DriverHub — Driver Performance Report</h2>
    <p style="margin: 4px 0; color: #666;">
        Period: <?= esc($start_date) ?> to <?= esc($end_date) ?>
        (<?= esc($date_range_days) ?> days)
        | Generated: <?= date('Y-m-d H:i') ?>
        | Total drivers: <?= esc($total_drivers) ?>
    </p>
    <hr>
</div>

<!-- Screen header -->
<div class="d-flex justify-content-between align-items-center mb-4 no-print">
    <div>
        <h3 class="mb-1">Driver Performance Reports</h3>
        <p class="text-muted mb-0">Multi-metric evaluation across the selected date range</p>
    </div>
    <button class="btn btn-primary" onclick="window.print()">
        <i class="bi bi-printer"></i> Print Report
    </button>
</div>

<!-- Date range filter -->
<div class="card mb-4 no-print">
    <div class="card-body">
        <form method="get" class="row g-3 align-items-end">
            <div class="col-md-4">
                <label class="form-label">Start date</label>
                <input type="date" name="start_date" class="form-control"
                       value="<?= esc($start_date) ?>">
            </div>
            <div class="col-md-4">
                <label class="form-label">End date</label>
                <input type="date" name="end_date" class="form-control"
                       value="<?= esc($end_date) ?>">
            </div>
            <div class="col-md-4">
                <button type="submit" class="btn btn-primary me-2">
                    <i class="bi bi-funnel"></i> Apply Filter
                </button>
                <a href="<?= site_url('admin/reports') ?>" class="btn btn-outline-secondary">
                    Reset
                </a>
            </div>
        </form>
    </div>
</div>

<!-- Summary cards -->
<div class="row mb-4 no-print">
    <div class="col-md-3">
        <div class="card text-center">
            <div class="card-body">
                <div class="h2 mb-0" style="color: #6B0E2F;"><?= esc($total_drivers) ?></div>
                <small class="text-muted">Total drivers</small>
            </div>
        </div>
    </div>
    <div class="col-md-3">
        <div class="card text-center">
            <div class="card-body">
                <div class="h2 mb-0" style="color: #6B0E2F;"><?= esc($date_range_days) ?></div>
                <small class="text-muted">Days in range</small>
            </div>
        </div>
    </div>
    <div class="col-md-3">
        <div class="card text-center">
            <div class="card-body">
                <div class="h2 mb-0" style="color: #C9942D;">
                    <?= !empty($reports)
                        ? round(array_sum(array_column($reports, 'overall_score')) / count($reports), 1)
                        : 0 ?>%
                </div>
                <small class="text-muted">Average performance</small>
            </div>
        </div>
    </div>
    <div class="col-md-3">
        <div class="card text-center">
            <div class="card-body">
                <div class="h2 mb-0" style="color: #C9942D;">
                    <?= array_sum(array_column($reports, 'total_trips')) ?>
                </div>
                <small class="text-muted">Total trips</small>
            </div>
        </div>
    </div>
</div>

<!-- Performance table -->
<div class="card">
    <div class="card-header" style="background: #6B0E2F; color: #fff;">
        <strong>Driver Performance Evaluation</strong>
        <small class="float-end">All metrics weighted equally (16.67% each)</small>
    </div>
    <div class="card-body p-0">
        <div class="table-responsive">
            <table class="table table-hover mb-0">
                <thead style="background: #f8f9fa;">
                    <tr>
                        <th>#</th>
                        <th>Driver</th>
                        <th class="text-center">Trips</th>
                        <th class="text-center">On Time</th>
                        <th class="text-center">Cancels</th>
                        <th class="text-center">Volunteers</th>
                        <th class="text-center">Leave Days</th>
                        <th class="text-center">Service</th>
                        <th class="text-center">Punctuality</th>
                        <th class="text-center">Availability</th>
                        <th class="text-center">Reliability</th>
                        <th class="text-center">Overall</th>
                        <th class="text-center">Rating</th>
                    </tr>
                </thead>
                <tbody>
                    <?php if (empty($reports)): ?>
                        <tr>
                            <td colspan="13" class="text-center py-4 text-muted">
                                No drivers found.
                            </td>
                        </tr>
                    <?php else: ?>
                        <?php foreach ($reports as $i => $r): ?>
                        <tr>
                            <td><?= $i + 1 ?></td>
                            <td>
                                <strong><?= esc($r['name']) ?></strong><br>
                                <small class="text-muted"><?= esc($r['email']) ?></small>
                            </td>
                            <td class="text-center"><?= $r['total_trips'] ?></td>
                            <td class="text-center">
                                <span class="text-success"><?= $r['on_time_trips'] ?></span>
                                / <?= $r['total_trips'] ?>
                            </td>
                            <td class="text-center"><?= $r['cancel_trips'] ?></td>
                            <td class="text-center">
                                <span class="text-primary"><?= $r['volunteer_trips'] ?></span>
                            </td>
                            <td class="text-center"><?= $r['leave_days'] ?></td>
                            <td class="text-center"><?= $r['months_service'] ?> mo</td>
                            <td class="text-center metric-cell">
                                <span class="metric-bar">
                                    <span style="width: <?= $r['punctuality_pct'] ?>%"></span>
                                </span>
                                <?= $r['punctuality_pct'] ?>%
                            </td>
                            <td class="text-center metric-cell">
                                <span class="metric-bar">
                                    <span style="width: <?= $r['availability_pct'] ?>%"></span>
                                </span>
                                <?= $r['availability_pct'] ?>%
                            </td>
                            <td class="text-center metric-cell">
                                <span class="metric-bar">
                                    <span style="width: <?= $r['cancellation_pct'] ?>%"></span>
                                </span>
                                <?= $r['cancellation_pct'] ?>%
                            </td>
                            <td class="text-center">
                                <span class="score-badge score-<?= $r['rating_class'] === 'success' ? 'excellent'
                                    : ($r['rating_class'] === 'primary' ? 'good'
                                    : ($r['rating_class'] === 'warning' ? 'fair'
                                    : ($r['rating_class'] === 'secondary' ? 'nodata' : 'poor'))) ?>">
                                    <?= $r['overall_score'] ?>%
                                </span>
                            </td>
                            <td class="text-center">
                                <span class="badge bg-<?= $r['rating_class'] ?>">
                                    <?= esc($r['rating']) ?>
                                </span>
                            </td>
                        </tr>
                        <?php endforeach; ?>
                    <?php endif; ?>
                </tbody>
            </table>
        </div>
    </div>
</div>

<!-- Methodology footer -->
<div class="card mt-3 no-print">
    <div class="card-body small text-muted">
        <strong>Performance scoring methodology:</strong>
        Each driver's overall score is the average of six metrics, weighted equally (16.67% each):
        <strong>Punctuality</strong> (% of trips started and ended within 5 minutes of expected times),
        <strong>Availability</strong> (inverse of approved leave days),
        <strong>Cancellation history</strong> (inverse of approved cancellation rate),
        <strong>Volunteer contributions</strong> (approved volunteer pickups per week),
        <strong>Total trips completed</strong> (trips per week productivity), and
        <strong>Length of service</strong> (months tenured, capped at 24 months).
        Rating bands: Excellent (90%+), Good (75-89%), Fair (60-74%), Needs improvement (&lt;60%).
    </div>
</div>
