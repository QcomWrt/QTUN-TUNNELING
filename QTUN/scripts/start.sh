#!/system/bin/sh

# Pastikan semua variabel menggunakan nama qtun
scripts_dir="/data/adb/QTUN/scripts"
run_dir="/data/adb/QTUN/run"
moddir="/data/adb/modules/qtun_tunneling" # Sesuaikan dengan nama folder modul kamu
busybox="/data/adb/magisk/busybox"

# Cek keberadaan busybox di berbagai lingkungan root
[ -f "/data/adb/ksu/bin/busybox" ] && busybox="/data/adb/ksu/bin/busybox"
[ -f "/data/adb/ap/bin/busybox" ] && busybox="/data/adb/ap/bin/busybox"

mkdir -p "$run_dir"

wait_for_data_ready() {
  while [ ! -f "/data/system/packages.xml" ] ; do
    sleep 1
  done
}

refresh_qtun() {
  if [ -f "${run_dir}/qtun.pid" ]; then
    "${scripts_dir}/qtun.service" stop >> "${run_dir}/run.log" 2>&1
    "${scripts_dir}/qtun.iptables" disable >> "${run_dir}/run.log" 2>&1
  fi
}

start_service() {
  if [ ! -f "${moddir}/disable" ]; then
    "${scripts_dir}/qtun.service" start >> "${run_dir}/run.log" 2>&1
  fi
}

enable_iptables() {
  # List binary yang digunakan QTUN untuk dicek PID-nya
  PIDS=("clash" "libuz" "libload")
  PID=""
  
  for p in "${PIDS[@]}"; do
    PID=$($busybox pidof "$p")
    [ -n "$PID" ] && break
  done

  if [ -n "$PID" ]; then
    "${scripts_dir}/qtun.iptables" enable >> "${run_dir}/run.log" 2>&1
  fi
}

# Eksekusi Utama
if [ -f "/data/adb/QTUN/manual" ]; then
  # Jika ada file 'manual', jangan jalankan otomatis saat boot
  exit 1
fi

wait_for_data_ready
echo "--- QTUN Auto-Start $(date) ---" > "${run_dir}/run.log"
refresh_qtun
start_service
enable_iptables