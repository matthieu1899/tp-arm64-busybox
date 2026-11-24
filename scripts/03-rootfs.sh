#!/usr/bin/env bash
# Construit l'arborescence minimale de la cible (rootfs/) : BusyBox + php-cgi + site web.
set -euo pipefail
source "$(dirname "$0")/env.sh"

SRC="$BUILD/busybox-$BUSYBOX_VERSION"

rm -rf "$ROOTFS"
mkdir -p "$ROOTFS"

# 1. Installe busybox + les liens symboliques des applets (bin/, sbin/, usr/)
make -C "$SRC" CROSS_COMPILE="$CROSS_COMPILE" CONFIG_PREFIX="$ROOTFS" install >/dev/null
rm -f "$ROOTFS/linuxrc"   # inutile : on fournit notre propre /init

# 2. Répertoires du système (FHS minimal)
cd "$ROOTFS"
mkdir -p dev proc sys tmp run root etc var/log var/www
chmod 1777 tmp
chmod 700 root

# 3. Script d'init (PID 1)
install -m 755 "$TOP/files/init" init

# 4. php-cgi statique (compilé par 02b-php.sh)
if [ -f "$OUT/php-cgi" ]; then
  install -D -m 755 "$OUT/php-cgi" usr/bin/php-cgi
else
  echo "ATTENTION : $OUT/php-cgi absent — lancer d'abord 02b-php.sh"
fi

# 5. Fichiers de configuration, site web, script DHCP (files/overlay/ recopié tel quel)
cp -a "$TOP/files/overlay/." .
chmod 755 usr/share/udhcpc/default.script
chmod 644 var/www/*.php etc/httpd.conf etc/php/php.ini

echo "arm64-busybox" > etc/hostname
cat > etc/passwd <<'EOF'
root:x:0:0:root:/root:/bin/sh
www:x:33:33:www:/var/www:/bin/false
EOF
cat > etc/group <<'EOF'
root:x:0:
www:x:33:
EOF
cat > etc/profile <<'EOF'
export PATH=/bin:/sbin:/usr/bin:/usr/sbin
export PS1='[\u@\h \w]# '
EOF

echo "== rootfs prêt : $(du -sh "$ROOTFS" | cut -f1) =="
