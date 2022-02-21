#!/usr/bin/with-contenv sh

set -u # Treat unset variables as an error.

FILEBOT_BETA_INDEX_URL="https://get.filebot.net/filebot/BETA"

log() {
    if [ -n "${1-}" ]; then
        echo "[cont-init.d] $(basename $0): $*"
    else
        while read OUTPUT; do
            echo "[cont-init.d] $(basename $0): $OUTPUT"
        done
    fi
}

# Determine if usage of FileBot beta is enabled.
USE_FILEBOT_BETA="$(echo "${USE_FILEBOT_BETA:-0}" | tr '[:upper:]' '[:lower:]')"
case "$USE_FILEBOT_BETA" in
    1|true|yes|enable|enabled)
        log "usage of FileBot beta version is enabled."
        if [ -f /config/beta/jar/filebot.jar ]; then
            # FileBot beta already installed.
            echo -n "/config/beta" > /var/run/s6/container_environment/FILEBOT_HOME
            exit 0
        else
            log "no FileBot beta installation found."
        fi
        ;;
    *)
        log "usage of FileBot beta version is not enabled."
        exit 0
        ;;
esac

# Download list of beta files from FileBot website.
log "fetching list of FileBot beta files..."
INDEX="$(mktemp)"
ERR="$(curl -fsSL --max-time 10 -o "$INDEX" "$FILEBOT_BETA_INDEX_URL" 2>&1)"
if [ $? -ne 0 ]; then
    log "ERROR: could not fetch list of FileBot beta files: $ERR."
    exit 0
fi

# Extract from the index the package filename we need to download.
PACKAGE_FILENAME="$(grep -o '"FileBot_[0-9\.]\+-portable.tar.xz"' "$INDEX" | head -n1 | tr -d '"')"
rm "$INDEX"
if [ -z "$PACKAGE_FILENAME" ]; then
    log "ERROR: FileBot beta package file name not found."
    exit 0
else
    log "found file: $PACKAGE_FILENAME"
fi

# Download the FileBot beta package.
TMP_DIR="$(mktemp -d)"
log "downloading $PACKAGE_FILENAME..."
curl -# -L --show-error --fail https://get.filebot.net/filebot/BETA/"$PACKAGE_FILENAME" | tar xJ -C "$TMP_DIR"
if [ $? -ne 0 ]; then
    log "ERROR: could not download $PACKAGE_FILENAME."
    rm -rf "$TMP_DIR"
    return 0
fi

# Install FileBot beta.
log "installing FileBot beta to /config/beta..."
rm -rf /config/beta
mv "$TMP_DIR" /config/beta
rm -r /config/beta/lib /config/beta/*.sh

# Use FileBot beta.
echo -n "/config/beta" > /var/run/s6/container_environment/FILEBOT_HOME

# Take ownership of the config directory content.
chown -R $USER_ID:$GROUP_ID /config/beta

log "FileBot beta successfully installed."

# vim: set ft=sh :
