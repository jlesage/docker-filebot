#!/bin/sh

# force JVM language and encoding settings
export LANG="en_US.UTF-8"
export LC_ALL="en_US.UTF-8"

APP_ROOT=/opt/filebot
APP_DATA=/config

# choose extractor
EXTRACTOR="ApacheVFS"					# use Apache Commons VFS2 with junrar plugin
# EXTRACTOR="SevenZipExecutable"		# use the 7z executable
# EXTRACTOR="SevenZipNativeBindings"	# use the lib7-Zip-JBinding.so native library

# start filebot
exec /usr/lib/jvm/java-1.8-openjdk/bin/java \
    -Dunixfs=false \
    -DuseGVFS=false \
    -DuseExtendedFileAttributes=true \
    -DuseCreationDate=false \
    -Djava.net.useSystemProxies=false \
    -Dapplication.deployment=portable \
    -Dfile.encoding="UTF-8" \
    -Dsun.jnu.encoding="UTF-8" \
    -Djna.nosys=false \
    -Djna.nounpack=true \
    -Djna.boot.library.path=/usr/lib \
    -Xbootclasspath/p:/usr/share/java/jna.jar \
    -Dnet.filebot.Archive.extractor="$EXTRACTOR" \
    -Dnet.filebot.AcoustID.fpcalc="fpcalc" \
    -Dnet.filebot.util.prefs.file="$APP_DATA/prefs.properties" \
    -Dapplication.dir="$APP_DATA" \
    -Dapplication.update=skip \
    -Duser.home="$APP_DATA" \
    -Djava.io.tmpdir="/tmp/filebot" \
    -Djava.util.prefs.PreferencesFactory=net.filebot.util.prefs.FilePreferencesFactory \
    $JAVA_OPTS -jar "$APP_ROOT/FileBot.jar" "$@"
