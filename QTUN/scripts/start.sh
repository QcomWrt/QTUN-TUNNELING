#!/system/bin/sh

scripts_dir="/data/adb/QTUN/scripts"
run_dir="/data/adb/QTUN/run"
moddir="/data/adb/modules/qtun_tunneling"

if [ -f "${moddir}/disable" ]; then exit 0; fi

mkdir -p "$run_dir"

log_run() {
    echo "[$(date '+%H:%M:%S')] $1" >> "$run_dir/run.log"
}

wait_for_data_ready() {
    while [ ! -f "/data/system/packages.xml" ]; do sleep 1; done
}

wait_for_data_ready

echo "=== QTUN BOOT ===" > "$run_dir/run.log"
log_run "[BOOT] Starting QTUN..."

"$scripts_dir/qtun.tool" stop 2>/dev/null

log_run "[CORE] Starting Clash..."
if "$scripts_dir/qtun.tool" start; then
    sleep 5

    log_run "[IPTABLES] Applying rules..."
    "$scripts_dir/qtun.iptables" renew

    log_run "[SUCCESS] Boot sequence selesai."
    log_run "[FINISH] Zivpn & Clash is Ready!"
else
    log_run "[FAIL] Clash failed to start"
fi
