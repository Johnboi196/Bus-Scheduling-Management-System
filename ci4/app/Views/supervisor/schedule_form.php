<?php
$isEdit = $mode === 'edit';
$action = $isEdit ? '/supervisor/schedules/update/' . $sched['schedule_id']
                  : '/supervisor/schedules/store';
?>
<div class="card">
    <div class="card-header bg-white">
        <strong><?= $isEdit ? 'Edit Schedule' : 'Create New Schedule' ?></strong>
    </div>
    <div class="card-body">
        <form method="post" action="<?= $action ?>">
            <?= csrf_field() ?>
            <div class="row g-3">
                <div class="col-md-6">
                    <label class="form-label">Driver</label>
                    <select name="driver_id" class="form-select" required>
                        <option value="">-- Select driver --</option>
                        <?php foreach ($drivers as $d): ?>
                            <option value="<?= $d['driver_id'] ?>"
                                <?= $isEdit && $sched['driver_id']==$d['driver_id'] ? 'selected':'' ?>>
                                <?= esc($d['full_name']) ?>
                            </option>
                        <?php endforeach; ?>
                    </select>
                </div>

                <div class="col-md-6">
                    <label class="form-label">Bus</label>
                    <select name="bus_id" class="form-select" required>
                        <option value="">-- Select bus --</option>
                        <?php foreach ($buses as $b): ?>
                            <option value="<?= $b['bus_id'] ?>"
                                <?= $isEdit && $sched['bus_id']==$b['bus_id'] ? 'selected':'' ?>>
                                <?= esc($b['plate_number']) ?> (<?= esc($b['mac_address']) ?>)
                            </option>
                        <?php endforeach; ?>
                    </select>
                </div>

                <div class="col-md-6">
                    <label class="form-label">Route</label>
                    <select name="route_id" class="form-select" required>
                        <option value="">-- Select route --</option>
                        <?php foreach ($routes as $r): ?>
                            <option value="<?= $r['route_id'] ?>"
                                <?= $isEdit && $sched['route_id']==$r['route_id'] ? 'selected':'' ?>>
                                <?= esc($r['route_name']) ?> (<?= esc($r['origin']) ?> → <?= esc($r['destination']) ?>)
                            </option>
                        <?php endforeach; ?>
                    </select>
                </div>

                <div class="col-md-6">
                    <label class="form-label">Date</label>
                    <input type="date" name="schedule_date" class="form-control" required
                           value="<?= esc($isEdit ? $sched['schedule_date'] : date('Y-m-d')) ?>">
                </div>

                <div class="col-md-6">
                    <label class="form-label">Expected Start</label>
                    <input type="time" name="expected_start" class="form-control" required
                           value="<?= esc($isEdit ? $sched['expected_start'] : '08:00') ?>">
                </div>

                <div class="col-md-6">
                    <label class="form-label">Expected End</label>
                    <input type="time" name="expected_end" class="form-control" required
                           value="<?= esc($isEdit ? $sched['expected_end'] : '10:00') ?>">
                </div>
            </div>

            <hr>
            <button class="btn btn-primary">
                <i class="bi bi-check-circle"></i> <?= $isEdit ? 'Save Changes' : 'Create Schedule' ?>
            </button>
            <a href="<?= site_url('supervisor/schedules') ?>" class="btn btn-outline-secondary">Cancel</a>
        </form>
    </div>
</div>
