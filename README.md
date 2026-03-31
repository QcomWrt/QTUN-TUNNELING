# QTUN
clash custom zivpn core

1. Push ke Folder Temporary

# Bersihkan dulu folder lama di tmp (jika ada)
adb shell "rm -rf /data/local/tmp/QTUN"

# Push folder dari laptop ke folder sementara
adb push QTUN /data/local/tmp/

2. Pindahkan ke /data/adb/ via Root

Sekarang kita pindahkan foldernya sendiri pakai akses su:

# Hapus folder QTUN lama di adb (jika ada) agar bersih
adb shell "su -c 'rm -rf /data/adb/QTUN'"

# Pindahkan dari tmp ke adb
adb shell "su -c 'mv /data/local/tmp/QTUN /data/adb/'"

# Beri izin eksekusi (penting!)
adb shell "su -c 'chmod -R 755 /data/adb/QTUN/'"

adb shell "su -c 'chmod 755 /data/adb/QTUN/scripts/qtun.service'"

adb shell "su -c 'chown -R root:root /data/adb/QTUN/'"

3. Tes Eksekusi dari device

Setelah dipindahkan pakai cara di atas, sekarang coba jalankan servicenya:
Bash

adb shell "su -c '/data/adb/QTUN/scripts/qtun.service start'"

adb shell "su -c '/data/adb/QTUN/scripts/qtun.service start'"

5. Pantau Log (Monitor Pergerakan)

Buka tab terminal baru untuk pantau apakah semua worker Libuz/zivpn dan Clash-nya naik dengan selamat:

adb shell "tail -f /data/adb/QTUN/run/run.log"
