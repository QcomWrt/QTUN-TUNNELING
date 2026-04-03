#!/system/bin/sh

# Dasar Modul
SKIPUNZIP=1
QTUN_DIR="/data/adb/QTUN"

# --- TAMPILAN INSTALASI ---
ui_print "-----------------------------------------------------------"
ui_print "                QTUN TUNNELING PROJECT                     "
ui_print "-----------------------------------------------------------"
ui_print "- Author     : azyanggara"
ui_print "- Version    : $(grep_prop version $MODPATH/module.prop)"
ui_print "- Build Date : $(grep_prop buildDate $MODPATH/module.prop)"
ui_print "- Platform   : $([ "$KSU" = true ] && echo "KernelSU" || echo "Magisk")"
ui_print "-----------------------------------------------------------"

# --- VALIDASI BOOTMODE ---
if [ "$BOOTMODE" != true ]; then
  ui_print "! Mohon install melalui aplikasi Magisk/KernelSU Manager"
  abort "-----------------------------------------------------------"
fi

# --- PROSES EKSTRAKSI ---
ui_print "- Mengekstrak file modul..."
unzip -o "$ZIPFILE" -x 'META-INF/*' -d "$MODPATH" >&2

# --- MANAJEMEN FOLDER /data/adb/QTUN ---
if [ -d "$MODPATH/QTUN" ]; then
  ui_print "- Deploying core files to $QTUN_DIR"
  
  # Backup config jika sudah ada
  if [ -f "$QTUN_DIR/libuz/config.json" ]; then
    ui_print "- Mempertahankan konfigurasi lama..."
    cp "$QTUN_DIR/libuz/config.json" /sdcard/qtun_config_bak.json
  fi
  
  # Hapus folder lama dan ganti dengan yang baru
  rm -rf "$QTUN_DIR"
  mv "$MODPATH/QTUN" /data/adb/
  
  # Restore config jika ada backupnya
  if [ -f /sdcard/qtun_config_bak.json ]; then
    mv /sdcard/qtun_config_bak.json "$QTUN_DIR/libuz/config.json"
    rm -f /sdcard/qtun_config_bak.json
  fi
fi

# --- SETTING PERMISSIONS ---
ui_print "- Mengatur izin akses..."

# 1. Set Permission Folder Utama QTUN (GID 3004 untuk Network)
# Format: set_perm_recursive <folder> <owner> <group> <dir_permission> <file_permission>
set_perm_recursive "$QTUN_DIR" 0 3004 0755 0644
chmod -R +x "$QTUN_DIR/bin/"
chmod -R +x "$QTUN_DIR/scripts/"

# 2. Set Permission Folder Modul (PENTING untuk Action & Service)
# Kita hapus instalasi ke service.d agar kontrol ON/OFF kembali ke Magisk App
set_perm_recursive "$MODPATH" 0 0 0755 0755
set_perm "$MODPATH/service.sh" 0 0 0755
set_perm "$MODPATH/action.sh" 0 0 0755
set_perm "$MODPATH/uninstall.sh" 0 0 0755
set_perm /data/adb/modules/qtun_tunneling/action.sh 0 0 0755

ui_print "-----------------------------------------------------------"
ui_print "          INSTALLATION DONE! REBOOT DEVICE                 "
ui_print "-----------------------------------------------------------"