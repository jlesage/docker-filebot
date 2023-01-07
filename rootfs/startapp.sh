#!/bin/sh

export HOME=/config

cd /storage
exec /opt/filebot/filebot ${FILEBOT_CUSTOM_OPTIONS:-}
