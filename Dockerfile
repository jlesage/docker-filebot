#
# filebot Dockerfile
#
# https://github.com/jlesage/docker-filebot
#

# Pull base image.
FROM jlesage/baseimage-gui:alpine-3.9-v3.5.7

# Docker image version is provided via build arg.
ARG DOCKER_IMAGE_VERSION=unknown

# Define software versions.
ARG FILEBOT_VERSION=4.9.4
ARG OPENJFX_VERSION=8.151.12-r0
ARG CHROMAPRINT_VERSION=1.4.3
ARG MEDIAINFOLIB_VERSION=21.03

# Define software download URLs.
ARG FILEBOT_URL=https://get.filebot.net/filebot/FileBot_${FILEBOT_VERSION}/FileBot_${FILEBOT_VERSION}-portable-jdk8.tar.xz
ARG OPENJFX_URL=https://github.com/sgerrand/alpine-pkg-java-openjfx/releases/download/${OPENJFX_VERSION}/java-openjfx-${OPENJFX_VERSION}.apk
ARG CHROMAPRINT_URL=https://github.com/acoustid/chromaprint/archive/v${CHROMAPRINT_VERSION}.tar.gz
ARG MEDIAINFOLIB_URL=https://mediaarea.net/download/source/libmediainfo/${MEDIAINFOLIB_VERSION}/libmediainfo_${MEDIAINFOLIB_VERSION}.tar.xz

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
    # Compile MediaInfoLib.
    echo "Compiling MediaInfoLib..." && \
    cd MediaInfoLib/Project/CMake && \
    cmake -DCMAKE_BUILD_TYPE=None \
          -DCMAKE_INSTALL_PREFIX=/usr \
          -DCMAKE_VERBOSE_MAKEFILE=OFF \
          -DBUILD_SHARED_LIBS=ON \
          && \
    make -j$(nproc) install && \
    cd ../../../ && \
    # Strip.
    strip -v /usr/lib/libmediainfo.so && \
    cd ../ && \
    # Cleanup.
    rm -r \
        /usr/include/MediaInfo \
        /usr/include/MediaInfoDLL \
        /usr/lib/cmake/mediainfolib \
        /usr/lib/pkgconfig/libmediainfo.pc \
        && \
    del-pkg build-dependencies && \
    rm -rf /tmp/* /tmp/.[!.]*

# Install dependencies.
RUN \
    add-pkg --virtual build-dependencies curl && \
    # OpenJFX
    curl -# -L -o java-openjfx.apk ${OPENJFX_URL} && \
    apk --no-cache add --allow-untrusted ./java-openjfx.apk && \
    add-pkg \
        bash \
        p7zip \
        unrar \
        findutils \
        coreutils \
        nss \
        gtk+2.0 \
        gsettings-desktop-schemas \
        dconf \
        openjdk8-jre \
        java-jna \
        # For libmediainfo.
        libzen \
        libcurl \
        tinyxml2 \
        && \
    # YAD
    add-pkg yad && \
    # Cleanup.
    del-pkg build-dependencies && \
    rm -rf /tmp/* /tmp/.[!.]*

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
        -DBUILD_TOOLS=ON \
        .. && \
    make -j$(nproc) && \
    make install && \
    cd .. && \
    cd .. && \
    # Cleanup.
    del-pkg build-dependencies && \
    rm /usr/lib/pkgconfig/libchromaprint.pc \
       /usr/include/chromaprint.h \
       && \
    rmdir /usr/include \
          /usr/lib/pkgconfig \
          && \
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
