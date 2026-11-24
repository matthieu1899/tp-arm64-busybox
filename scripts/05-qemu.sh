#!/usr/bin/env bash
# Démarre la cible dans QEMU (machine "virt", CPU Cortex-A53 comme le Raspberry Pi 3).
# Réseau : mode "user" (NAT de QEMU, DHCP intégré -> 10.0.2.15) + carte VirtIO.
# hostfwd : le port 8080 de la VM Debian est redirigé vers le port 80 de la cible.
# Quitter QEMU : Ctrl-A puis X
set -euo pipefail
source "$(dirname "$0")/env.sh"

HOST_PORT="${HOST_PORT:-8080}"

exec qemu-system-aarch64 \
  -M virt -cpu cortex-a53 -smp 2 -m 512M \
  -nographic -no-reboot \
  -kernel "$OUT/Image" \
  -initrd "$OUT/initramfs.cpio.gz" \
  -append "console=ttyAMA0 rdinit=/init panic=5" \
  -netdev user,id=net0,hostfwd=tcp::"$HOST_PORT"-:80 \
  -device virtio-net-pci,netdev=net0
