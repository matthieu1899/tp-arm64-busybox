#!/usr/bin/env bash
# Compile php-cgi en STATIQUE pour aarch64, avec le strict minimum d'extensions.
set -euo pipefail
source "$(dirname "$0")/env.sh"

TARBALL="php-$PHP_VERSION.tar.xz"
URL="https://www.php.net/distributions/$TARBALL"
SRC="$BUILD/php-$PHP_VERSION"

# 1. Téléchargement + empreinte (à comparer avec celle publiée sur php.net/downloads)
cd "$DL"
[ -f "$TARBALL" ] || wget -O "$TARBALL" "$URL"
echo "SHA-256 de $TARBALL : $(sha256sum "$TARBALL" | cut -d' ' -f1)"
if [ -n "${PHP_SHA256:-}" ]; then
  echo "$PHP_SHA256  $TARBALL" | sha256sum -c -
fi

[ -d "$SRC" ] || tar -xf "$TARBALL" -C "$BUILD"
cd "$SRC"

# 2. Configuration croisée minimale : seulement le SAPI CGI + le cœur du langage
if [ ! -f Makefile ]; then
  ./configure \
    --build=x86_64-linux-gnu --host=aarch64-linux-gnu \
    CC="${CROSS_COMPILE}gcc" LDFLAGS="-static" \
    --prefix=/usr --with-config-file-path=/etc/php \
    --disable-all \
    --enable-cgi --disable-cli --disable-phpdbg \
    --disable-opcache --without-pear --without-pcre-jit
fi

# 3. Compilation ; -all-static force libtool à lier le binaire en statique
time make -j"$JOBS" EXTRA_LDFLAGS_PROGRAM=-all-static

# 4. Allègement + vérification
"${CROSS_COMPILE}strip" sapi/cgi/php-cgi
cp sapi/cgi/php-cgi "$OUT/php-cgi"
cp config.nice "$TOP/configs/php-config.nice"   # options de configure, pour la reproductibilité

echo
file "$OUT/php-cgi"
file "$OUT/php-cgi" | grep -q "statically linked" || { echo "ERREUR : php-cgi n'est pas statique"; exit 1; }
ls -lh "$OUT/php-cgi"
echo "== php-cgi statique ARM64 prêt =="
