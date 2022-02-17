#!/usr/bin/with-contenv sh

set -e # Exit immediately if a command exits with a non-zero status.
set -u # Treat unset variables as an error.

run() {
    j=1
    while eval "\${pipestatus_$j+:} false"; do
        unset pipestatus_$j
        j=$(($j+1))
    done
    j=1 com= k=1 l=
    for a; do
        if [ "x$a" = 'x|' ]; then
            com="$com { $l "'3>&-
                        echo "pipestatus_'$j'=$?" >&3
                      } 4>&- |'
            j=$(($j+1)) l=
        else
            l="$l \"\$$k\""
        fi
        k=$(($k+1))
    done
    com="$com $l"' 3>&- >&4 4>&-
               echo "pipestatus_'$j'=$?"'
    exec 4>&1
    eval "$(exec 3>&1; eval "$com")"
    exec 4>&-
    j=1
    while eval "\${pipestatus_$j+:} false"; do
        eval "[ \$pipestatus_$j -eq 0 ]" || return 1
        j=$(($j+1))
    done
    return 0
}

log() {
    if [ -n "${1-}" ]; then
        echo "[cont-init.d] $(basename $0): $*"
    else
        while read OUTPUT; do
            echo "[cont-init.d] $(basename $0): $OUTPUT"
        done
    fi
}

LICENSE_FILE_NAME="license.psm"
LICENSE_PATH=/config/"$LICENSE_FILE_NAME"

# Make sure required directories exists
mkdir -p "$XDG_DATA_HOME"

# Copy default config.
if [ ! -f /config/prefs.properties ]; then
    cp /defaults/prefs.properties /config/
    touch /config/.licensed_version
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
            log "existing license will be replaced."
            mv "$LICENSE_PATH" "$LICENSE_PATH".old
        fi
        log "installing license file $(basename "$LFILE")..."
        mv "$LFILE" "$LICENSE_PATH"
    else
        log "multiple license files found: skipping installation"
    fi
fi

# Set OpenSubtitles credentials.
if [ -n "${OPENSUBTITLES_USERNAME:-}" ] && [ -n "${OPENSUBTITLES_PASSWORD:-}" ]; then
    printf "$OPENSUBTITLES_USERNAME\n$OPENSUBTITLES_PASSWORD\n" | /opt/filebot/filebot -script fn:configure
fi

# Install requested packages.
if [ "${AMC_INSTALL_PKGS:-UNSET}" != "UNSET" ]; then
    log "installing requested package(s)..."
    for PKG in $AMC_INSTALL_PKGS; do
        if cat /etc/apk/world | grep -wq "$PKG"; then
            log "package '$PKG' already installed"
        else
            log "installing '$PKG'..."
            run add-pkg "$PKG" 2>&1 \| log
        fi
    done
fi

# Take ownership of the config directory content.
find /config -mindepth 1 -exec chown $USER_ID:$GROUP_ID {} \;

# Take ownership of the output directory.
if ! chown $USER_ID:$GROUP_ID /output; then
    # Failed to take ownership of /output.  This could happen when,
    # for example, the folder is mapped to a network share.
    # Continue if we have write permission, else fail.
    TMPFILE="$(s6-setuidgid $USER_ID:$GROUP_ID mktemp /output/.test_XXXXXX 2>/dev/null)"
    if [ $? -eq 0 ]; then
        # Success, we were able to write file.
        s6-setuidgid $USER_ID:$GROUP_ID rm "$TMPFILE"
    else
        log "ERROR: Failed to take ownership and no write permission on /output."
        exit 1
    fi
fi

# vim: set ft=sh :
