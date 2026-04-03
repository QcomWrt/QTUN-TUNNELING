#!/system/bin/sh

# Jalur folder QTUN
QTUN_DIR="/data/adb/QTUN"

# 1. Matikan proses binary
killall libuz libload clash 2>/dev/null

# 2. Matikan Iptables (WAJIB agar internet tidak putus setelah uninstall)
if [ -f "$QTUN_DIR/scripts/qtun.iptables" ]; then
    sh "$QTUN_DIR/scripts/qtun.iptables" disable >/dev/null 2>&1
fi

# 3. Hapus folder utama QTUN
[ -d "$QTUN_DIR" ] && rm -rf "$QTUN_DIR"

# 4. Hapus backup config di sdcard
rm -f /sdcard/qtun_config_bak.json

ui_print "- QTUN Uninstalled Successfully."