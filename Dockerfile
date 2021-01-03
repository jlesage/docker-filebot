#
# filebot Dockerfile
#
# https://github.com/jlesage/docker-filebot
#

# Pull base image.
FROM jlesage/baseimage-gui:alpine-3.9-v3.5.6

# Docker image version is provided via build arg.
ARG DOCKER_IMAGE_VERSION=unknown

# Define software versions.
ARG FILEBOT_VERSION=4.7.9
ARG OPENJFX_VERSION=8.151.12-r0
ARG CHROMAPRINT_VERSION=1.4.3

# Define software download URLs.
ARG OPENJFX_URL=https://github.com/sgerrand/alpine-pkg-java-openjfx/releases/download/${OPENJFX_VERSION}/java-openjfx-${OPENJFX_VERSION}.apk
ARG CHROMAPRINT_URL=https://github.com/acoustid/chromaprint/archive/v${CHROMAPRINT_VERSION}.tar.gz

# Define working directory.
WORKDIR /tmp

COPY downloads/FileBot_4.7.9-portable.tar.xz /tmp/FileBot_4.7.9-portable.tar.xz

# Install FileBot.
RUN \
    # Extract sources.
    tar -xf FileBot_4.7.9-portable.tar.xz FileBot.jar && \
    # Install.
    mkdir /opt/filebot && \
    cp -Rv FileBot.jar /opt/filebot/filebot.jar && \
    # Cleanup.
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
        libmediainfo \
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
      org.label-schema.vcs-url="https://github.com/NeverminedDE/docker-filebot" \
      org.label-schema.schema-version="1.0"
