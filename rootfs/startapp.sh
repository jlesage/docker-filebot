#!/bin/sh
/opt/filebot/filebot.sh -script fn:sysinfo

export JAVA_OPTS="-Dprism.verbose=true -Djava.awt.headless=false -Dawt.useSystemAAFontSettings=on -Dprism.order=sw"
exec /opt/filebot/filebot.sh
