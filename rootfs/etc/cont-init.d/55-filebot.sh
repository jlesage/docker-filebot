#!/bin/sh

set -e # Exit immediately if a command exits with a non-zero status.
set -u # Treat unset variables as an error.

LICENSE_FILE_NAME="license.psm"
LICENSE_PATH=/config/"$LICENSE_FILE_NAME"

# Make sure required directories exists
mkdir -p "$XDG_DATA_HOME"

# Copy default config.
if [ ! -f /config/prefs.properties ]; then
    cp /defaults/prefs.properties /config/
fi

# Clear the fstab file to make sure its content is not displayed when opening
# files.
echo > /etc/fstab

# Install the license to the proper location.
LFILE="$(find /config -maxdepth 1 ! -name "$LICENSE_FILE_NAME" -name "*.psm" -type f)"
if [ "${LFILE:-UNSET}" != "UNSET" ]; then
    LFILE_COUNT="$(echo "$LFILE" | wc -l)"
    if [ "$LFILE_COUNT" -eq 1 ]; then
        if [ -f "$LICENSE_PATH" ]; then
            echo "existing license will be replaced."
            mv "$LICENSE_PATH" "$LICENSE_PATH".old
        fi
        echo "installing license file $(basename "$LFILE")..."
        mv "$LFILE" "$LICENSE_PATH"
    else
        echo "multiple license files found: skipping installation"
    fi
fi

# Set OpenSubtitles credentials.
if [ -n "${OPENSUBTITLES_USERNAME:-}" ] && [ -n "${OPENSUBTITLES_PASSWORD:-}" ]; then
    printf "$OPENSUBTITLES_USERNAME\n$OPENSUBTITLES_PASSWORD\n" | /opt/filebot/filebot -script fn:configure
fi

# Set dark mode.
# https://www.filebot.net/forums/viewtopic.php?t=9827
# [System, CrossPlatform, Darcula, Nimbus, Metal]
if is-bool-val-true "${FILEBOT_GUI:-1}"; then
    if is-bool-val-true "${DARK_MODE:-0}"; then
        /opt/filebot/filebot -script fn:properties --def net.filebot.theme=Darcula
        touch /config/.dark_mode
    elif [ -f /config/.dark_mode ]; then
        /opt/filebot/filebot -script fn:properties --def net.filebot.theme=Nimbus
        rm /config/.dark_mode
    fi
fi

# Take ownership of the output directory.
take-ownership --not-recursive /output

# vim:ft=sh:ts=4:sw=4:et:sts=4
