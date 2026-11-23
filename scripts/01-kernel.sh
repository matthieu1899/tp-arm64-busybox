#!/usr/bin/env bash
# Télécharge, vérifie, configure et compile le noyau Linux mainline pour arm64 (cible QEMU virt).
set -euo pipefail
source "$(dirname "$0")/env.sh"

TARBALL="linux-$KERNEL_VERSION.tar.xz"
URL="https://cdn.kernel.org/pub/linux/kernel/v${KERNEL_VERSION%%.*}.x"
SRC="$BUILD/linux-$KERNEL_VERSION"
SAVED_CONFIG="$TOP/configs/kernel-qemu.config"

# 1. Téléchargement + vérification d'intégrité (SHA-256 publiés par kernel.org)
cd "$DL"
[ -f "$TARBALL" ] || wget "$URL/$TARBALL"
[ -f kernel-sha256sums.asc ] || wget -O kernel-sha256sums.asc "$URL/sha256sums.asc"
grep " $TARBALL\$" kernel-sha256sums.asc | sha256sum -c -

# 2. Extraction
[ -d "$SRC" ] || tar -xf "$TARBALL" -C "$BUILD"
cd "$SRC"

KMAKE=(make ARCH="$KARCH" CROSS_COMPILE="$CROSS_COMPILE")

# 3. Configuration : on réutilise la config sauvegardée si elle existe (reproductibilité)
if [ -f "$SAVED_CONFIG" ]; then
  cp "$SAVED_CONFIG" .config
else
  "${KMAKE[@]}" defconfig
  # Pas de modules : tout est intégré au noyau -> build plus court, pas de /lib/modules sur la cible
  ./scripts/config \
    --disable MODULES \
    --enable BLK_DEV_INITRD --enable RD_GZIP \
    --enable DEVTMPFS \
    --enable SERIAL_AMBA_PL011 --enable SERIAL_AMBA_PL011_CONSOLE \
    --enable VIRTIO --enable VIRTIO_PCI --enable VIRTIO_MMIO \
    --enable VIRTIO_NET
fi
"${KMAKE[@]}" olddefconfig

# 4. Compilation de l'image (pas de modules)
time "${KMAKE[@]}" -j"$JOBS" Image

cp arch/arm64/boot/Image "$OUT/Image"
cp .config "$SAVED_CONFIG"
echo "== Noyau prêt : $OUT/Image (config sauvegardée dans configs/) =="
