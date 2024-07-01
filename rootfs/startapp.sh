#!/bin/sh

export HOME=/config

cd /storage
exec /opt/filebot/filebot ${FILEBOT_CUSTOM_OPTIONS:-}

# vim:ft=sh:ts=4:sw=4:et:sts=4
