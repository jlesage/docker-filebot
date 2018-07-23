#!/usr/bin/with-contenv sh
/opt/filebot/filebot -script fn:sysinfo
exec /opt/filebot/filebot-gui
