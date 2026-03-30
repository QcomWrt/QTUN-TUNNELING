1. Push ke Folder Temporary
Bash

# Bersihkan dulu folder lama di tmp (jika ada)
adb shell "rm -rf /data/local/tmp/QTUN"

# Push folder dari laptop ke folder sementara
adb push QTUN /data/local/tmp/

2. Pindahkan ke /data/adb/ via Root

Sekarang kita suruh si Kenzo memindahkan foldernya sendiri pakai akses su:
Bash

# Hapus folder QTUN lama di adb (jika ada) agar bersih
adb shell "su -c 'rm -rf /data/adb/QTUN'"

# Pindahkan dari tmp ke adb
adb shell "su -c 'mv /data/local/tmp/QTUN /data/adb/'"

# Beri izin eksekusi (penting!)
adb shell "su -c 'chmod -R 755 /data/adb/QTUN/'"
adb shell "su -c 'chmod 755 /data/adb/QTUN/scripts/qtun.service'"
adb shell "su -c 'chown -R root:root /data/adb/QTUN/'"

3. Cek Status Symbolic Link di Kenzo

Mari kita buktikan apakah clash sudah mengarah ke mihomo dengan benar di sisi Android:
Bash

adb shell "su -c 'ls -l /data/adb/QTUN/bin/clash'"

4. Tes Eksekusi dari Kenzo

Setelah dipindahkan pakai cara di atas, sekarang coba jalankan servicenya:
Bash

adb shell "su -c '/data/adb/QTUN/scripts/qtun.service start'"

5. Pantau Log (Monitor Pergerakan)

Buka tab terminal baru untuk pantau apakah 8 worker Hysteria dan Clash-nya naik dengan selamat:
Bash

adb shell "tail -f /data/adb/QTUN/run/run.log"