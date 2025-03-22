#!/bin/sh

set -e # Exit immediately if a command exits with a non-zero status.
set -u # Treat unset variables as an error.

# Set same default compilation flags as abuild.
export CFLAGS="-Os -fomit-frame-pointer"
export CXXFLAGS="$CFLAGS"
export CPPFLAGS="$CFLAGS"
export LDFLAGS="-Wl,--strip-all -Wl,--as-needed"

export CC=xx-clang
export CXX=xx-clang++
export STRIP=echo

log() {
    echo ">>> $*"
}

UNRAR_URL="$1"

if [ -z "$UNRAR_URL" ]; then
    log "ERROR: unrar URL missing."
    exit 1
fi

#
# Install required packages.
#
apk --no-cache add \
    curl \
    clang \
    patch \
    make

apk --no-cache --no-scripts add \
    musl-dev \
    gcc \
    g++

#
# Download sources.
#
log "Downloading unrar package..."
TMP_DIR="/tmp/unrar"
mkdir -p "$TMP_DIR"
if ! curl -# -L -f "${UNRAR_URL}" | tar xz --strip 1 -C "$TMP_DIR"; then
    log "ERROR: Failed to download or extract unrar package."
    exit 1
fi

log "Patching unrar..."
if ! patch -d "$TMP_DIR" -p1 < /build/makefile.patch; then
    log "ERROR: Failed to apply patch."
    exit 1
fi

log "Compiling unrar..."
if [ ! -f "$TMP_DIR/makefile" ]; then
    log "ERROR: Makefile not found in the unrar source directory."
    exit 1
fi

make -C "$TMP_DIR" -f makefile -j"$(nproc)"

log "Installing unrar..."
make DESTDIR=/tmp/unrar-install/usr -C "$TMP_DIR" -f makefile install

# Cleanup
log "Cleaning up..."
rm -rf "$TMP_DIR"

log "Unrar installation completed successfully."
