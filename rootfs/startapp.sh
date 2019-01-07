#!/usr/bin/with-contenv sh

show_upgrade_info() {
    URL="$1"
    XDG_BASE="$(mktemp -d)"

    export XDG_DATA_HOME="$XDG_BASE/xdg/data"
    export XDG_CONFIG_HOME="$XDG_BASE/xdg/config"
    export XDG_CACHE_HOME="$XDG_BASE/xdg/cache"

    yad \
        --fixed \
        --center \
        --title "$APP_NAME" \
        --window-icon /opt/novnc/images/icons/master_icon.png \
        --borders 10 \
        --image dialog-information \
        --image-on-top \
        --text "<b>$APP_NAME Now Requires a License</b>" \
        --form \
        --field "Purchase of a license is now required to use all features of $APP_NAME.\n\nFor more information or for instruction on on to revert to the donation supported version of $APP_NAME, please see :\n\n<span foreground=\"blue\">https://github.com/jlesage/docker-filebot</span>:LBL" \
        --button=gtk-ok:0 > /dev/null || true

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
exec /opt/filebot/filebot
