#!/usr/bin/env bash
# Génère l'initramfs (archive cpio "newc" compressée gzip) à partir de rootfs/.
# fakeroot permet de créer les nœuds de périphériques et d'attribuer root:root
# aux fichiers sans exécuter le script en root.
set -euo pipefail
source "$(dirname "$0")/env.sh"

cd "$ROOTFS"
fakeroot -- sh -c '
  rm -f dev/console dev/null
  mknod -m 600 dev/console c 5 1   # nécessaire AVANT que /init ne monte devtmpfs
  mknod -m 666 dev/null    c 1 3
  find . -print0 | cpio --null -o -H newc -R 0:0 --quiet
' | gzip -9 > "$OUT/initramfs.cpio.gz"

ls -lh "$OUT/initramfs.cpio.gz"
