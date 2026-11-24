# Variables communes — à "sourcer" par tous les scripts (source scripts/env.sh)
# Versions figées pour un build reproductible.

KERNEL_VERSION="6.12"          # noyau mainline (branche LTS)
BUSYBOX_VERSION="1.36.1"
PHP_VERSION="8.4.25"           # branche 8.4 (support sécurité)

CROSS_COMPILE="aarch64-linux-gnu-"   # toolchain Debian (gcc-aarch64-linux-gnu)
KARCH="arm64"                         # ARCH côté noyau

TOP="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DL="$TOP/dl"          # archives téléchargées
BUILD="$TOP/build"    # sources extraites + compilation
ROOTFS="$TOP/rootfs"  # arborescence de la cible
OUT="$TOP/out"        # Image noyau + initramfs
JOBS="$(nproc)"

mkdir -p "$DL" "$BUILD" "$OUT"
