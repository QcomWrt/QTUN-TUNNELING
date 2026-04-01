#!/system/bin/sh

# Dasar Modul
SKIPUNZIP=1
QTUN_DIR="/data/adb/QTUN"

# --- TAMPILAN INSTALASI (AUTHOR FOCUS) ---
ui_print "-----------------------------------------------------------"
ui_print "               QTUN TUNNELING PROJECT                      "
ui_print "-----------------------------------------------------------"
ui_print "- Author     : azyanggara"
ui_print "- Version    : $(grep_prop version $MODPATH/module.prop)"
ui_print "- Build Date : $(date +%d-%m-%Y)"
ui_print "- Platform   : $([ "$KSU" = true ] && echo "KernelSU" || echo "Magisk")"
ui_print "-----------------------------------------------------------"
ui_print "- Status     : Deploying to /data/adb/QTUN"

# --- VALIDASI DASAR ---
if [ "$BOOTMODE" != true ]; then
  ui_print "! Mohon install melalui aplikasi Magisk/KernelSU Manager"
  abort "-----------------------------------------------------------"
fi

# --- PROSES INSTALASI ---
ui_print "- Mengekstrak file modul..."
unzip -o "$ZIPFILE" -x 'META-INF/*' -d "$MODPATH" >&2

# Pindahkan folder utama ke /data/adb/
if [ -d "$MODPATH/QTUN" ]; then
  # Backup config lama sementara jika ada (biar user tidak setting ulang)
  [ -f "$QTUN_DIR/libuz/config.json" ] && cp "$QTUN_DIR/libuz/config.json" /sdcard/qtun_config_bak.json
  
  rm -rf "$QTUN_DIR"
  mv "$MODPATH/QTUN" /data/adb/
  
  # Restore config jika tadi di-backup
  [ -f /sdcard/qtun_config_bak.json ] && mv /sdcard/qtun_config_bak.json "$QTUN_DIR/libuz/config.json"
fi

# --- PERMISSIONS & GID 3004 ---
ui_print "- Mengatur izin akses (GID: 3004)..."
# Set permission folder utama dengan GID 3004 (Network Raw)
set_perm_recursive "$QTUN_DIR" 0 3004 0755 0644
# Pastikan bin dan scripts bisa dieksekusi (+x)
chmod -R +x "$QTUN_DIR/bin/"
chmod -R +x "$QTUN_DIR/scripts/"

service_dir="/data/adb/service.d"
[ "$KSU" = true ] && [ "$KSU_VER_CODE" -lt 10683 ] && service_dir="/data/adb/ksu/service.d"
mkdir -p "$service_dir"

ui_print "- Memasang Auto-start..."
unzip -j -o "$ZIPFILE" 'service.sh' -d "$service_dir" >&2
chmod 755 "$service_dir/service.sh"
mv "$service_dir/service.sh" "$service_dir/qtun_service.sh"

# 2. Set permission untuk action.sh (Agar tombol di Magisk App muncul)
ui_print "- Memasang Action script..."
set_perm $MODPATH/action.sh 0 0 0755

# --- Tambahkan ini di bawah bagian memasang Action script ---
ui_print "- Memasang Uninstall script..."
unzip -j -o "$ZIPFILE" 'uninstall.sh' -d "$MODPATH" >&2
set_perm "$MODPATH/uninstall.sh" 0 0 0755

ui_print "-----------------------------------------------------------"
ui_print "          INSTALLATION DONE! REBOOT DEVICE                 "
ui_print "-----------------------------------------------------------"