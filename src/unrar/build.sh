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

function log {
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
    make \

xx-apk --no-cache --no-scripts add \
    musl-dev \
    gcc \
    g++ \

#
# Download sources.
#

log "Downloading unrar package..."
mkdir /tmp/unrar
curl -# -L -f ${UNRAR_URL} | tar xz --strip 1 -C /tmp/unrar

log "Patching unrar..."
patch -d /tmp/unrar -p1 < /build/makefile.patch

log "Compiling unrar..."
make -C /tmp/unrar -f makefile -j$(nproc)

log "Installing unrar..."
make DESTDIR=/tmp/unrar-install/usr -C /tmp/unrar -f makefile install
