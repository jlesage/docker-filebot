#
# filebot Dockerfile
#
# https://github.com/jlesage/docker-filebot
#

# Build unrar.  It has been moved to non-free since Alpine 3.15.
# https://wiki.alpinelinux.org/wiki/Release_Notes_for_Alpine_3.15.0#unrar_moved_to_non-free
FROM jlesage/alpine-abuild:3.15 AS unrar
WORKDIR /tmp
RUN \
    mkdir /tmp/aport && \
    cd /tmp/aport && \
    git init && \
    git remote add origin https://git.alpinelinux.org/aports && \
    git config core.sparsecheckout true && \
    echo "non-free/unrar/*" >> .git/info/sparse-checkout && \
    git pull origin 3.15-stable && \
    PKG_SRC_DIR=/tmp/aport/non-free/unrar && \
    PKG_DST_DIR=/tmp/unrar-pkg && \
    mkdir "$PKG_DST_DIR" && \
    /bin/start-build -r && \
    rm /tmp/unrar-pkg/*-doc-* && \
    mkdir /tmp/unrar-install && \
    tar xf /tmp/unrar-pkg/unrar-*.apk -C /tmp/unrar-install

# Pull base image.
FROM jlesage/baseimage-gui:alpine-3.15-v3.5.8

# Docker image version is provided via build arg.
ARG DOCKER_IMAGE_VERSION=unknown

# Define software versions.
ARG FILEBOT_VERSION=4.9.4
ARG CHROMAPRINT_VERSION=1.5.1
ARG MEDIAINFOLIB_VERSION=21.09
ARG YAD_VERSION=10.1

# Define software download URLs.
ARG FILEBOT_URL=https://get.filebot.net/filebot/FileBot_${FILEBOT_VERSION}/FileBot_${FILEBOT_VERSION}-portable.tar.xz
ARG CHROMAPRINT_URL=https://github.com/acoustid/chromaprint/archive/v${CHROMAPRINT_VERSION}.tar.gz
ARG MEDIAINFOLIB_URL=https://mediaarea.net/download/source/libmediainfo/${MEDIAINFOLIB_VERSION}/libmediainfo_${MEDIAINFOLIB_VERSION}.tar.xz
ARG YAD_URL=https://github.com/v1cont/yad/releases/download/v${YAD_VERSION}/yad-${YAD_VERSION}.tar.xz

# Define working directory.
WORKDIR /tmp

# Install FileBot.
RUN \
    add-pkg --virtual build-dependencies curl && \
    mkdir filebot && \
    # Download sources.
    curl -# -L ${FILEBOT_URL} | tar xJ -C filebot && \
    # Install.
    mkdir /opt/filebot && \
    cp -Rv filebot/jar /opt/filebot/ && \
    # Cleanup.
    del-pkg build-dependencies && \
    rm -rf /tmp/* /tmp/.[!.]*

# Compile and install MediaInfo library.
RUN \
    # Install packages needed by the build.
    add-pkg --virtual build-dependencies \
        build-base \
        curl \
        cmake \
        automake \
        autoconf \
        libtool \
        curl-dev \
        libzen-dev \
        tinyxml2-dev \
        && \
    # Set same default compilation flags as abuild.
    export CFLAGS="-Os -fomit-frame-pointer" && \
    export CXXFLAGS="$CFLAGS" && \
    export CPPFLAGS="$CFLAGS" && \
    export LDFLAGS="-Wl,--as-needed" && \
    # Download MediaInfoLib.
    echo "Downloading MediaInfoLib package..." && \
    mkdir MediaInfoLib && \
    curl -# -L ${MEDIAINFOLIB_URL} | tar xJ --strip 1 -C MediaInfoLib && \
    rm -r \
        MediaInfoLib/Project/MS* \
        MediaInfoLib/Project/zlib \
        MediaInfoLib/Source/ThirdParty/tinyxml2 \
        && \
    curl -# -L https://github.com/MediaArea/MediaInfoLib/commit/cd6d5cb1cfe03d4fcef8fd38decd04765c19890a.patch | patch -p1 -d MediaInfoLib && \
    # Compile MediaInfoLib.
    echo "Compiling MediaInfoLib..." && \
    cd MediaInfoLib/Project/CMake && \
    cmake -DCMAKE_BUILD_TYPE=None \
          -DCMAKE_INSTALL_PREFIX=/usr \
          -DCMAKE_VERBOSE_MAKEFILE=OFF \
          -DBUILD_SHARED_LIBS=ON \
          && \
    make -j$(nproc) && \
    make DESTDIR=/tmp/libmediainfo-install install && \
    cd ../../../ && \
    # Install MediaInfoLib.
    cp -av /tmp/libmediainfo-install/usr/lib/libmediainfo.so* /usr/lib/ && \
    # Strip.
    strip -v /usr/lib/libmediainfo.so.*.* && \
    cd ../ && \
    # Cleanup.
    del-pkg build-dependencies && \
    rm -rf /tmp/* /tmp/.[!.]*

# Install dependencies.
RUN \
    add-pkg \
        bash \
        p7zip \
        findutils \
        coreutils \
        gtk+3.0 \
        ttf-dejavu \
        gnome-icon-theme \
        openjdk17-jre \
        java-jna-native \
        # For chromaprint (fpcalc)
        ffmpeg-libs \
        # For libmediainfo.
        libzen \
        libcurl \
        tinyxml2 \
        && \
    true

# Build and install chromaprint (fpcalc) for AcousItD.
RUN \
    add-pkg --virtual build-dependencies \
        build-base \
        cmake \
        curl \
        ffmpeg-dev \
        fftw-dev \
        && \
    # Download.
    mkdir chromaprint && \
    curl -# -L ${CHROMAPRINT_URL} | tar xz --strip 1 -C chromaprint && \
    # Compile.
    cd chromaprint && \
    mkdir build && cd build && \
    cmake \
        -DCMAKE_INSTALL_PREFIX=/usr \
        -DCMAKE_BUILD_TYPE=Release \
        -DBUILD_SHARED_LIBS=OFF \
        -DBUILD_TOOLS=ON \
        -DBUILD_TESTS=OFF \
        .. && \
    make -j$(nproc) && \
    make DESTDIR=/tmp/chromaprint-install install && \
    cd .. && \
    cd .. && \
    cp -v /tmp/chromaprint-install/usr/bin/fpcalc /usr/bin/ && \
    strip /usr/bin/fpcalc && \
    # Cleanup.
    del-pkg build-dependencies && \
    rm -rf /tmp/* /tmp/.[!.]*

# Build and install YAD.
# NOTE: YAD is compiled manually because the version on the Alpine repository
#       pulls too much dependencies.
RUN \
    # Install packages needed by the build.
    add-pkg --virtual build-dependencies \
        build-base \
        curl \
        intltool \
        gtk+3.0-dev \
        && \
    # Set same default compilation flags as abuild.
    export CFLAGS="-Os -fomit-frame-pointer" && \
    export CXXFLAGS="$CFLAGS" && \
    export CPPFLAGS="$CFLAGS" && \
    export LDFLAGS="-Wl,--as-needed" && \
    # Download.
    mkdir yad && \
    echo "Downloading YAD package..." && \
    curl -# -L ${YAD_URL} | tar xJ --strip 1  -C yad && \
    # Compile.
    cd yad && \
    ./configure \
        --prefix=/usr \
        --enable-standalone \
        --disable-icon-browser \
        --disable-html \
        --disable-spell \
        --disable-sourceview \
        --disable-tools \
        --disable-tray \
        && \
    make -j$(nproc) && \
    make install && \
    strip /usr/bin/yad && \
    cd .. && \
    # Cleanup.
    del-pkg build-dependencies && \
    rm -rf /tmp/* /tmp/.[!.]*

# Adjust the openbox config.
RUN \
    # Maximize only the main window.
    sed-patch 's/<application type="normal">/<application type="normal" title="FileBot \*">/' \
        /etc/xdg/openbox/rc.xml && \
    # Make sure the main window is always in the background.
    sed-patch '/<application type="normal" title="FileBot \*">/a \    <layer>below</layer>' \
        /etc/xdg/openbox/rc.xml

# Generate and install favicons.
RUN \
    APP_ICON_URL=https://raw.githubusercontent.com/jlesage/docker-templates/master/jlesage/images/filebot-icon.png && \
    install_app_icon.sh "$APP_ICON_URL"

# Add files.
COPY rootfs/ /
COPY --from=unrar /tmp/unrar-install/usr/bin/unrar /usr/bin/

# Set environment variables.
ENV APP_NAME="FileBot" \
    OPENSUBTITLES_USERNAME= \
    OPENSUBTITLES_PASSWORD= \
    AMC_INTERVAL="1800" \
    AMC_INPUT_STABLE_TIME="10" \
    AMC_ACTION="test" \
    AMC_CONFLICT="auto" \
    AMC_MATCH_MODE="opportunistic" \
    AMC_ARTWORK="n" \
    AMC_LANG="English" \
    AMC_MUSIC_FORMAT="{plex}" \
    AMC_MOVIE_FORMAT="{plex}" \
    AMC_SERIES_FORMAT="{plex}" \
    AMC_ANIME_FORMAT="{plex}" \
    AMC_PROCESS_MUSIC="y" \
    AMC_SUBTITLE_LANG= \
    AMC_CUSTOM_OPTIONS= \
    AMC_INPUT_DIR=/watch \
    AMC_OUTPUT_DIR=/output

# Define mountable directories.
VOLUME ["/config"]
VOLUME ["/storage"]
VOLUME ["/watch"]
VOLUME ["/output"]

# Metadata.
LABEL \
      org.label-schema.name="filebot" \
      org.label-schema.description="Docker container for FileBot" \
      org.label-schema.version="$DOCKER_IMAGE_VERSION" \
      org.label-schema.vcs-url="https://github.com/jlesage/docker-filebot" \
      org.label-schema.schema-version="1.0"
