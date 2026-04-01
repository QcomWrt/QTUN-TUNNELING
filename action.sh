#!/system/bin/sh
# File: action.sh (Root Modul)

# Cek apakah biner sedang jalan
if pgrep -x "clash" > /dev/null; then
    ui_print "- Stopping QTUN Service & Firewall..."
    /data/adb/QTUN/scripts/qtun.service stop
    /data/adb/QTUN/scripts/qtun.iptables disable
    ui_print "- QTUN is now OFFLINE."
else
    ui_print "- Starting QTUN Service & Firewall..."
    /data/adb/QTUN/scripts/qtun.service start
    # Jalankan iptables setelah biner siap
    sleep 5
    /data/adb/QTUN/scripts/qtun.iptables enable
    
    if [ $? -eq 0 ]; then
        ui_print "- QTUN is now ONLINE!"
    else
        ui_print "- Gagal mengaktifkan Firewall!"
    fi
fi