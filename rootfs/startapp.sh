#!/usr/bin/with-contenv sh

export HOME=/config

show_upgrade_info() {
    URL="$1"
    XDG_BASE="$(mktemp -d)"

    export XDG_DATA_HOME="$XDG_BASE/xdg/data"
    export XDG_CONFIG_HOME="$XDG_BASE/xdg/config"
    export XDG_CACHE_HOME="$XDG_BASE/xdg/cache"

    zenity \
        --warning \
        --title "$APP_NAME" \
        --window-icon /opt/novnc/images/icons/master_icon.png \
        --width=250 \
        --text "<b>$APP_NAME Now Requires a License</b>\n\nPurchase of a license is now required to use all features of $APP_NAME.\n\nFor more information or for instruction on how to revert to the donation supported version of $APP_NAME, please see :\n\n<span foreground=\"blue\">https://github.com/jlesage/docker-filebot</span>" || true

    rm -r "$XDG_BASE"
}

/opt/filebot/filebot -script fn:sysinfo

if [ ! -f /config/.licensed_version ]; then
    if [ ! -f /config/license.psm ]; then
        show_upgrade_info &
    fi
    touch /config/.licensed_version
fi

cd /storage
exec /opt/filebot/filebot ${FILEBOT_CUSTOM_OPTIONS:-}
