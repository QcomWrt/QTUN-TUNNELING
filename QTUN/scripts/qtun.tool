#!/system/bin/sh
# File: /data/adb/QTUN/scripts/qtun.tool

MODDIR="/data/adb/QTUN"
BIN="$MODDIR/bin"
YQ="$BIN/yq"
JQ="$BIN/jq"
RUNDIR="$MODDIR/run"

# Path Config & Template
TPL_UZ="$MODDIR/libuz/template-config.json"
CONF_UZ="$MODDIR/libuz/config.json"
TPL_CLASH="$MODDIR/clash/template-config.yaml"
CONF_CLASH="$MODDIR/clash/config.yaml"

GID_CLASH=3004
mkdir -p $RUNDIR

log_msg() {
    echo "[$(date '+%H:%M:%S')] $1" | tee -a $RUNDIR/run.log
}

case "$1" in
  start)
    echo "--- New Start Session ---" > $RUNDIR/run.log
    killall libuz libload clash 2>/dev/null
    sleep 0.5

    # 1. Cek & Buat Config dari Template jika tidak ada
    if [ ! -f "$CONF_UZ" ]; then
        log_msg "[WARN] config.json tidak ada. Membuat dari template..."
        cp "$TPL_UZ" "$CONF_UZ"
    fi
    if [ ! -f "$CONF_CLASH" ]; then
        log_msg "[WARN] config.yaml tidak ada. Membuat dari template..."
        cp "$TPL_CLASH" "$CONF_CLASH"
    fi

    # 2. Ambil IP VPS Terbaru (Untuk Sinkronisasi)
    RAW_SERVER=$($JQ -r '.server' "$CONF_UZ")
    IP_ONLY=$(echo $RAW_SERVER | cut -d':' -f1)
    
    if [ "$IP_ONLY" == "IP-VPS" ] || [ -z "$IP_ONLY" ]; then
        log_msg "[FATAL] Isi dulu akun VPS kamu di $CONF_UZ"
        exit 1
    fi

    # 3. Deteksi Core & Jalankan Workers (String Injection)
    CPU_CORES=$(grep -c ^processor /proc/cpuinfo)
    [ -z "$CPU_CORES" ] || [ "$CPU_CORES" -eq 0 ] && CPU_CORES=4
    log_msg "[1/3] Memulai $CPU_CORES Workers..."
    
    TUNNEL_LIST=""
    for i in $(busybox seq 0 $((CPU_CORES - 1))); do
        PORT=$((1080 + i))
        TUNNEL_LIST="$TUNNEL_LIST 127.0.0.1:$PORT"
        JSON_DATA=$(cat "$CONF_UZ" | sed "s/\"listen\": *\"[^\"]*\"/\"listen\": \"127.0.0.1:$PORT\"/g")
        $BIN/libuz -s 'hu``hqb`c' --config "$JSON_DATA" >> $RUNDIR/libuz.log 2>&1 &
        sleep 0.2
    done
    sleep 1

    # 4. Jalankan Aggregator
    log_msg "[2/3] Menjalankan Aggregator (Port 7777)..."
    $BIN/libload -lport 7777 -tunnel $TUNNEL_LIST >> $RUNDIR/libuz.log 2>&1 &
    sleep 2

    # 5. Sinkronisasi IP VPS ke Config Clash
    log_msg "[3/3] Sinkronisasi IP VPS ($IP_ONLY) ke Clash..."

    # REPLACE DI FAKE-IP-FILTER
    # Mencari baris yang tepat berisi "IP-VPS" dan menggantinya dengan IP asli
    $YQ -i "(.dns.fake-ip-filter[] | select(. == \"IP-VPS\")) = \"$IP_ONLY\"" "$CONF_CLASH"

    # REPLACE DI RULES
    # Mencari baris yang mengandung teks "IP-VPS" dan menggantinya dengan format IP-CIDR lengkap
    $YQ -i "(.rules[] | select(contains(\"IP-VPS\"))) = \"IP-CIDR,$IP_ONLY/32,DIRECT\"" "$CONF_CLASH"
    
    # Jalankan Clash
    setuidgid 0:$GID_CLASH $BIN/clash -d $MODDIR/clash -f $CONF_CLASH > $RUNDIR/clash.log 2>&1 &
    
    # Verifikasi Akhir
    if $BIN/curl -so /dev/null -x socks5h://127.0.0.1:7777 --connect-timeout 5 http://www.google.com; then
        log_msg "[SUCCESS] QTUN Online!"
    else
        log_msg "[FATAL] Handshake gagal. Cek akun atau koneksi."
        killall libuz libload clash 2>/dev/null
        exit 1
    fi
    ;;

  stop)
    killall libuz libload clash 2>/dev/null
    log_msg "[STOP] Layanan dihentikan."
    ;;

  status)
    $BIN/jq -n "{\"workers\": \"$CPU_CORES\", \"status\": \"running\"}"
    ps -ef | grep -E 'libuz|libload|clash' | grep -v grep
    ;;
esac