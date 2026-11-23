#!/usr/bin/env bash
# Installe la chaîne de compilation croisée ARM64 et les outils de build (Debian 13).
set -euo pipefail

sudo apt update
sudo apt install -y \
  build-essential make bc bison flex \
  libssl-dev libelf-dev libncurses-dev \
  gcc-aarch64-linux-gnu binutils-aarch64-linux-gnu libc6-dev-arm64-cross \
  qemu-system-arm \
  wget xz-utils bzip2 cpio fakeroot file git

echo
echo "== Vérification de la toolchain =="
aarch64-linux-gnu-gcc --version | head -1
qemu-system-aarch64 --version | head -1
