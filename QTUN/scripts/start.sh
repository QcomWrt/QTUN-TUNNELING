#!/system/bin/sh
# File: /data/adb/QTUN/scripts/start.sh

scripts_dir="/data/adb/QTUN/scripts"
run_dir="/data/adb/QTUN/run"
moddir="/data/adb/modules/qtun_tunneling" 
busybox="/data/adb/magisk/busybox"

# 1. Cek Status Modul (Disable Toggle)
if [ -f "${moddir}/disable" ]; then
  exit 0
fi

# 2. Cek Manual Mode
if [ -f "/data/adb/QTUN/manual" ]; then
  exit 1
fi

[ -f "/data/adb/ksu/bin/busybox" ] && busybox="/data/adb/ksu/bin/busybox"
[ -f "/data/adb/ap/bin/busybox" ] && busybox="/data/adb/ap/bin/busybox"

mkdir -p "$run_dir"

# Fungsi untuk mencatat ke run.log
log_run() {
    echo "[$(date '+%H:%M:%S')] $1" >> "${run_dir}/run.log"
}

wait_for_data_ready() {
  while [ ! -f "/data/system/packages.xml" ] ; do
    sleep 1
  done
}

# --- EKSEKUSI UTAMA ---
wait_for_data_ready

# Reset log saat booting
echo "=== QTUN BOOT SESSION: $(date) ===" > "${run_dir}/run.log"

log_run "[START] Membersihkan sisa proses lama..."
"${scripts_dir}/qtun.service" stop >> "${run_dir}/run.log" 2>&1
"${scripts_dir}/qtun.iptables" disable >> "${run_dir}/run.log" 2>&1

log_run "[START] Menjalankan Core Service (libuz, libload, clash)..."
if "${scripts_dir}/qtun.service" start >> "${run_dir}/run.log" 2>&1;then
  log_run "[FIREWALL] Mengaktifkan aturan Iptables..."
  "${scripts_dir}/qtun.iptables" enable >> "${run_dir}/run.log" 2>&1

  log_run "[SUCCESS] Boot sequence selesai."
  log_run "[FINISH] Zivpn & Clash is Ready!"

else
  log_run "[ERROR] Core gagal start. Iptables dibatalkan demi keamanan."
  echo "FAILED: Check run.log!"
  exit 1
fi