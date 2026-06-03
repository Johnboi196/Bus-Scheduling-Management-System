<div class="row g-3 mb-4">
    <div class="col-md-4 col-lg-2">
        <div class="card stat-card p-3 text-center">
            <i class="bi bi-people fs-1 text-primary"></i>
            <div class="display-6"><?= $stats['drivers'] ?></div>
            <small class="text-muted">Drivers</small>
        </div>
    </div>
    <div class="col-md-4 col-lg-2">
        <div class="card stat-card p-3 text-center">
            <i class="bi bi-person-badge fs-1 text-primary"></i>
            <div class="display-6"><?= $stats['supervisors'] ?></div>
            <small class="text-muted">Supervisors</small>
        </div>
    </div>
    <div class="col-md-4 col-lg-2">
        <div class="card stat-card p-3 text-center">
            <i class="bi bi-bus-front fs-1 text-primary"></i>
            <div class="display-6"><?= $stats['buses'] ?></div>
            <small class="text-muted">Buses</small>
        </div>
    </div>
    <div class="col-md-4 col-lg-2">
        <div class="card stat-card p-3 text-center">
            <i class="bi bi-signpost-2 fs-1 text-primary"></i>
            <div class="display-6"><?= $stats['routes'] ?></div>
            <small class="text-muted">Routes</small>
        </div>
    </div>
    <div class="col-md-4 col-lg-2">
        <div class="card stat-card warn p-3 text-center">
            <i class="bi bi-calendar-event fs-1 text-warning"></i>
            <div class="display-6"><?= $stats['trips_today'] ?></div>
            <small class="text-muted">Trips Today</small>
        </div>
    </div>
    <div class="col-md-4 col-lg-2">
        <div class="card stat-card ok p-3 text-center">
            <i class="bi bi-check-circle fs-1 text-success"></i>
            <div class="display-6"><?= $stats['completed_today'] ?></div>
            <small class="text-muted">Completed</small>
        </div>
    </div>
</div>

<div class="row g-3">
    <div class="col-md-6">
        <div class="card">
            <div class="card-body">
                <h5><i class="bi bi-info-circle text-primary"></i> Welcome, Admin</h5>
                <p class="text-muted mb-3">
                    Use the sidebar to manage the fleet. The most important setup steps:
                </p>
                <ol class="mb-0">
                    <li>Register all <strong>Buses</strong> with their MAC addresses so the in-bus
                        tablets can identify themselves.</li>
                    <li>Create <strong>Routes</strong> the buses will run.</li>
                    <li>Create <strong>Driver</strong> and <strong>Supervisor</strong> accounts.</li>
                    <li>Supervisors then create daily schedules from their own dashboard.</li>
                </ol>
            </div>
        </div>
    </div>
    <div class="col-md-6">
        <div class="card">
            <div class="card-body">
                <h5><i class="bi bi-graph-up text-success"></i> Quick Actions</h5>
                <div class="d-grid gap-2 mt-3">
                    <a href="<?= site_url('admin/buses') ?>"       class="btn btn-outline-primary text-start">
                        <i class="bi bi-bus-front"></i> Register a new bus
                    </a>
                    <a href="<?= site_url('admin/drivers') ?>"     class="btn btn-outline-primary text-start">
                        <i class="bi bi-person-plus"></i> Add a driver
                    </a>
                    <a href="<?= site_url('admin/reports') ?>"     class="btn btn-outline-primary text-start">
                        <i class="bi bi-graph-up"></i> View weekly report
                    </a>
                </div>
            </div>
        </div>
    </div>
</div>
