#!/system/bin/sh

# Jalankan di background agar tidak menghambat booting
(
    # Tunggu sampai boot animation selesai (Sistem siap)
    until [ "$(getprop init.svc.bootanim)" = "stopped" ]; do
        sleep 5
    done

    # Beri jeda tambahan agar IP Modem/Wi-Fi dapat
    sleep 10

    if [ -f "/data/adb/QTUN/scripts/qtun.service" ]; then
        # Pastikan permission aman lagi (jaga-jaga)
        chmod 755 /data/adb/QTUN/scripts/*
        chmod 755 /data/adb/QTUN/bin/*
        
        # Jalankan QTUN
        /data/adb/QTUN/scripts/qtun.service start
        /data/adb/QTUN/scripts/qtun.iptables enable
    else
        echo "QTUN Service not found"
    fi
)&