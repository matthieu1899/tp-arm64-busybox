#!/usr/bin/env bash
# Démarre la cible dans QEMU (machine "virt", CPU Cortex-A53 comme le Raspberry Pi 3).
# Quitter QEMU : Ctrl-A puis X
set -euo pipefail
source "$(dirname "$0")/env.sh"

exec qemu-system-aarch64 \
  -M virt -cpu cortex-a53 -smp 2 -m 512M \
  -nographic -no-reboot \
  -kernel "$OUT/Image" \
  -initrd "$OUT/initramfs.cpio.gz" \
  -append "console=ttyAMA0 rdinit=/init panic=5"
