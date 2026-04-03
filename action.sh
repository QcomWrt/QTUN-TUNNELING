#!/system/bin/sh

# TAMBAHKAN INI di baris paling atas agar semua perintah sistem terbaca
export PATH=/sbin:/system/bin:/system/xbin:/data/adb/magisk:/data/adb/bin:$PATH

# Pastikan folder ada
mkdir -p /data/adb/QTUN/run

# --- FUNGSI STOP ---
stop_service() {
    echo "[-] QTUN: Stopping Services..." # Muncul di layar Magisk
    echo "[$(date '+%H:%M:%S')] --- Stop QTUN Session ---" >> /data/adb/QTUN/run/run.log
    
    /data/adb/QTUN/scripts/qtun.iptables disable >> /data/adb/QTUN/run/run.log 2>&1
    /data/adb/QTUN/scripts/qtun.service stop >> /data/adb/QTUN/run/run.log 2>&1
    
    rm -f /data/adb/QTUN/run/qtun.pid
    touch /data/adb/modules/qtun_tunneling/disable
    echo "[OK] Status: OFFLINE" # Muncul di layar Magisk
}

# --- FUNGSI START ---
start_service() {
    echo "[+] QTUN: Starting Services..." # Muncul di layar Magisk
    echo "[$(date '+%H:%M:%S')] [ACTION] Start Request" >> /data/adb/QTUN/run/run.log
    
    rm -f /data/adb/modules/qtun_tunneling/disable
    
    if /data/adb/QTUN/scripts/qtun.service start >> /data/adb/QTUN/run/run.log 2>&1; then
        /data/adb/QTUN/scripts/qtun.iptables enable >> /data/adb/QTUN/run/run.log 2>&1
        echo "[$(date '+%H:%M:%S')] [FINISH] Zivpn & Clash Berjalan!" >> /data/adb/QTUN/run/run.log
        echo "[OK] Status: ONLINE" # Muncul di layar Magisk
    else
        echo "[!] FAILED: Check /data/adb/QTUN/run/run.log"
        exit 1
    fi
}

# --- LOGIKA TOGGLE (Tetap Sama) ---
if [ -f "/data/adb/QTUN/run/qtun.pid" ]; then
    PID=$(cat "/data/adb/QTUN/run/qtun.pid")
    if [ -d "/proc/$PID" ]; then
        stop_service
    else
        rm -f "/data/adb/QTUN/run/qtun.pid"
        start_service
    fi
else
    if pgrep -x "clash" > /dev/null; then
        stop_service
    else
        start_service
    fi
fi