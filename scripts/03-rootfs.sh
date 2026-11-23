#!/usr/bin/env bash
# Construit l'arborescence minimale de la cible (rootfs/) à partir de BusyBox.
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

# 4. Fichiers de configuration minimaux
echo "arm64-busybox" > etc/hostname
cat > etc/passwd <<'EOF'
root:x:0:0:root:/root:/bin/sh
EOF
cat > etc/group <<'EOF'
root:x:0:
EOF
cat > etc/profile <<'EOF'
export PATH=/bin:/sbin:/usr/bin:/usr/sbin
export PS1='[\u@\h \w]# '
EOF

echo "== rootfs prêt : $(du -sh "$ROOTFS" | cut -f1) =="
