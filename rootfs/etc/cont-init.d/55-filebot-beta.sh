#!//bin/sh

set -u # Treat unset variables as an error.

FILEBOT_BETA_INDEX_URL="https://get.filebot.net/filebot/BETA"

# Determine if usage of FileBot beta is enabled.
if is-bool-val-true "${USE_FILEBOT_BETA:-0}"; then
    echo "usage of FileBot beta version is enabled."
    if [ -f /config/beta/jar/filebot.jar ]; then
        # FileBot beta already installed.
        exit 0
    else
        echo "no FileBot beta installation found."
    fi
else
    echo "usage of FileBot beta version is not enabled."
    exit 0
fi

# Download list of beta files from FileBot website.
echo "fetching list of FileBot beta files..."
INDEX="$(mktemp)"
ERR="$(curl -fsSL --max-time 10 -o "$INDEX" "$FILEBOT_BETA_INDEX_URL" 2>&1)"
if [ $? -ne 0 ]; then
    rm "$INDEX"
    echo "ERROR: could not fetch list of FileBot beta files: $ERR."
    exit 1
fi

# Extract from the index the package filename we need to download.
PACKAGE_FILENAME="$(grep -o '"FileBot_[0-9\.]\+-portable.tar.xz"' "$INDEX" | head -n1 | tr -d '"')"
rm "$INDEX"
if [ -z "$PACKAGE_FILENAME" ]; then
    echo "ERROR: FileBot beta package file name not found."
    exit 1
else
    echo "found file: $PACKAGE_FILENAME"
fi

# Download the FileBot beta package.
TMP_DIR="$(mktemp -d)"
echo "downloading $PACKAGE_FILENAME..."
curl -s -L --show-error --fail https://get.filebot.net/filebot/BETA/"$PACKAGE_FILENAME" | tar xJ -C "$TMP_DIR"
if [ $? -ne 0 ]; then
    echo "ERROR: could not download $PACKAGE_FILENAME."
    rm -rf "$TMP_DIR"
    exit 1
fi

# Install FileBot beta.
echo "installing FileBot beta to /config/beta..."
rm -rf /config/beta
mv "$TMP_DIR" /config/beta
rm -r /config/beta/lib /config/beta/*.sh

echo "FileBot beta successfully installed."

# vim:ft=sh:ts=4:sw=4:et:sts=4
