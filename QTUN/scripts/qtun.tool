#!/system/bin/sh
# File: /data/adb/QTUN/scripts/qtun.tool

# Penyesuaian Folder (Memisahkan direktori Binaries dan direktori Modul)
APPDIR="/data/adb/QTUN"
MODDIR="/data/adb/QTUN"
BIN="$APPDIR/bin"
YQ="$BIN/yq"
JQ="$BIN/jq"
RUNDIR="$APPDIR/run"
PIDFILE="$RUNDIR/qtun.pid"

# Path Config (Diarahkan ke qtun_tunneling)
TPL_UZ="$APPDIR/libuz/template-config.json"
CONF_UZ="$APPDIR/libuz/config.json"
TPL_CLASH="$APPDIR/clash/template-config.yaml"
CONF_CLASH="$APPDIR/clash/config.yaml"

GID_CLASH=3004
mkdir -p $RUNDIR

log_msg() {
    echo "[$(date '+%H:%M:%S')] $1" | tee -a $RUNDIR/run.log
}

cleanup_fail() {
    log_msg "[FATAL] $1. Menghentikan semua proses."
    killall libuz libload clash 2>/dev/null
    rm -f "$PIDFILE"
    echo "Service Failed at $(date)" >> $RUNDIR/libuz.log
    exit 1
}

case "$1" in
  start)
    echo "--- Start QTUN Session ---" > $RUNDIR/run.log
    killall libuz libload clash 2>/dev/null
    sleep 0.5

    # 1. Validasi Config
    [ ! -f "$CONF_UZ" ] && cp "$TPL_UZ" "$CONF_UZ"
    [ ! -f "$CONF_CLASH" ] && cp "$TPL_CLASH" "$CONF_CLASH"

    # Mengambil IP menggunakan jq (Sangat aman)
    RAW_SERVER=$($JQ -r '.server' "$CONF_UZ")
    IP_ONLY=$(echo $RAW_SERVER | cut -d':' -f1)
    
    if [ "$IP_ONLY" == "IP-VPS" ] || [ "$IP_ONLY" == "null" ] || [ -z "$IP_ONLY" ]; then
        log_msg "[FATAL] Akun VPS belum diisi di $CONF_UZ"
        exit 1
    fi

    # 2. Tahap 1: Jalankan libuz (Workers)
    CPU_CORES=$(grep -c ^processor /proc/cpuinfo)
    [ -z "$CPU_CORES" ] || [ "$CPU_CORES" -eq 0 ] && CPU_CORES=4
    log_msg "[1/3] Memulai $CPU_CORES libuz Workers..."
    
    TUNNEL_LIST=""
    for i in $(busybox seq 0 $((CPU_CORES - 1))); do
        PORT=$((1080 + i))
        TUNNEL_LIST="$TUNNEL_LIST 127.0.0.1:$PORT"
        JSON_DATA=$(cat "$CONF_UZ" | sed "s/\"listen\": *\"[^\"]*\"/\"listen\": \"127.0.0.1:$PORT\"/g")
        $BIN/libuz -s 'hu``hqb`c' --config "$JSON_DATA" >> $RUNDIR/libuz.log 2>&1 &
        sleep 0.2
    done
    
    sleep 2
    if ! pidof libuz >/dev/null; then
        cleanup_fail "libuz gagal berjalan (Cek akun/koneksi)"
    fi

    # 3. Tahap 2: Jalankan Aggregator (libload)
    log_msg "[2/3] Menjalankan Aggregator (Port 7777)..."
    $BIN/libload -lport 7777 -tunnel $TUNNEL_LIST >> $RUNDIR/libuz.log 2>&1 &
    
    sleep 2
    if ! pidof libload >/dev/null; then
        cleanup_fail "Aggregator (libload) gagal berjalan"
    fi

    # 4. Sinkronisasi Server (IP atau Domain) ke Clash
    log_msg "[3/3] Sinkronisasi Server ($IP_ONLY) ke Clash..."
    
    # Bersihkan input dari spasi atau enter tersembunyi
    CLEAN_IP=$(echo "$IP_ONLY" | tr -d '\r' | tr -d ' ')

    # Cek apakah input berupa IP atau Domain
    if ! echo "$CLEAN_IP" | grep -Eq '^[0-9]{1,3}(\.[0-9]{1,3}){3}$'; then
        log_msg "Mendeteksi Domain. Melacak IP dari $CLEAN_IP..."
        
        # [KODE SAKTI] Melacak IP asli dari domain menggunakan ping
        RESOLVED_IP=$(ping -c 1 -W 3 "$CLEAN_IP" | head -n 1 | awk -F'[()]' '{print $2}')
        
        if [ -z "$RESOLVED_IP" ]; then
            cleanup_fail "Gagal menerjemahkan domain $CLEAN_IP menjadi IP. Cek koneksi/domain!"
        fi
        
        log_msg "Berhasil! Domain $CLEAN_IP = IP $RESOLVED_IP"
        TARGET_IP="$RESOLVED_IP"
    else
        # Jika input sudah berupa IP, langsung gunakan
        TARGET_IP="$CLEAN_IP"
    fi

    # SELALU gunakan format IP untuk bypass di Clash agar tidak terjadi Routing Loop
    NEW_RULE="IP-CIDR,${TARGET_IP}\/32,DIRECT"
    NEW_FILTER="- \"${TARGET_IP}\""

    # a. Update fake-ip-filter (Menimpa 1 baris di bawah # QTUN-FILTER)
    sed -i '/# QTUN-FILTER/{n; s@.*@    '"$NEW_FILTER"'@; }' "$CONF_CLASH"

    # b. Update routing rules (Menimpa 1 baris di bawah # QTUN-RULE)
    sed -i '/# QTUN-RULE/{n; s@.*@  - '"$NEW_RULE"'@; }' "$CONF_CLASH"


    # 5. Tahap 3: Jalankan Clash (Hanya jika Aggregator OK)
    log_msg "Menjalankan Clash Core..."
    # Kita simpan PID Clash (proses terakhir) ke PIDFILE
    setuidgid 0:$GID_CLASH $BIN/clash -d $APPDIR/clash -f $CONF_CLASH > $RUNDIR/clash.log 2>&1 &
    echo $! > "$PIDFILE"
    
    sleep 2
    if ! pidof clash >/dev/null; then
        cleanup_fail "Clash gagal berjalan (Cek config.yaml)"
    fi

    # 6. Verifikasi Koneksi Akhir (Handshake Check)
    log_msg "Melakukan verifikasi koneksi ke Google..."
    
    # Mencoba koneksi melalui port Aggregator (7777)
    if $BIN/curl -so /dev/null -x socks5h://127.0.0.1:7777 --connect-timeout 5 http://www.google.com; then
        log_msg "[SUCCESS] QTUN System is ONLINE & Verified!"
    else
        cleanup_fail "Handshake gagal. Cek akun VPS atau koneksi internet."
    fi
    ;;

  stop)
    log_msg "[STOP] Menghentikan semua layanan QTUN..."
    killall libuz libload clash 2>/dev/null
    rm -f "$PIDFILE"
    log_msg "[STOP] Layanan berhasil dihentikan."
    ;;

  status)
    echo "--- QTUN Status ---"
    ps -ef | grep -E 'libuz|libload|clash' | grep -v grep
    [ -f "$PIDFILE" ] && echo "PID File: $(cat $PIDFILE)" || echo "PID File: NOT FOUND"
    ;;
esac
