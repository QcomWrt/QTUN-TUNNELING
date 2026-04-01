#!/system/bin/sh

# Jalur folder QTUN
QTUN_DIR="/data/adb/QTUN"
SERVICE_FILE="/data/adb/service.d/qtun_service.sh"

# 1. Matikan semua proses yang masih berjalan (Safety First)
killall libuz libload clash 2>/dev/null

# 2. Matikan Firewall/Iptables agar internet tidak putus setelah uninstall
# Kita panggil langsung script iptables-nya sebelum dihapus
if [ -f "$QTUN_DIR/scripts/qtun.iptables" ]; then
    "$QTUN_DIR/scripts/qtun.iptables" disable
fi

# 3. Hapus folder utama QTUN di /data/adb/
if [ -d "$QTUN_DIR" ]; then
    rm -rf "$QTUN_DIR"
fi

# 4. Hapus script auto-start di service.d
if [ -f "$SERVICE_FILE" ]; then
    rm -f "$SERVICE_FILE"
fi

# 5. Hapus file backup sementara jika ada di /sdcard
rm -f /sdcard/qtun_config_bak.json