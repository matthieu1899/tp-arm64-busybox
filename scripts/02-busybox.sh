#!/usr/bin/env bash
# Télécharge, vérifie et compile BusyBox en STATIQUE pour aarch64.
set -euo pipefail
source "$(dirname "$0")/env.sh"

TARBALL="busybox-$BUSYBOX_VERSION.tar.bz2"
URL="https://busybox.net/downloads"
SRC="$BUILD/busybox-$BUSYBOX_VERSION"
SAVED_CONFIG="$TOP/configs/busybox.config"

cd "$DL"
[ -f "$TARBALL" ] || wget "$URL/$TARBALL"
[ -f "$TARBALL.sha256" ] || wget "$URL/$TARBALL.sha256"
sha256sum -c "$TARBALL.sha256"

[ -d "$SRC" ] || tar -xf "$TARBALL" -C "$BUILD"
cd "$SRC"

BMAKE=(make CROSS_COMPILE="$CROSS_COMPILE")

if [ -f "$SAVED_CONFIG" ]; then
  cp "$SAVED_CONFIG" .config
else
  "${BMAKE[@]}" defconfig
  # Binaire statique : aucune dépendance à une libc sur la cible
  sed -i 's/^# CONFIG_STATIC is not set/CONFIG_STATIC=y/' .config
  # L'applet "tc" ne compile plus avec les en-têtes noyau récents (>= 6.8, CBQ supprimé)
  sed -i 's/^CONFIG_TC=y/# CONFIG_TC is not set/' .config
fi
{ yes "" || true; } | "${BMAKE[@]}" oldconfig >/dev/null

time "${BMAKE[@]}" -j"$JOBS"

cp .config "$SAVED_CONFIG"
echo
file busybox
file busybox | grep -q "statically linked" || { echo "ERREUR : busybox n'est pas statique"; exit 1; }
echo "== BusyBox statique ARM64 prête =="
