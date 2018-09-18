#
# filebot Dockerfile
#
# https://github.com/jlesage/docker-filebot
#

# Pull base image.
FROM jlesage/baseimage-gui:alpine-3.8-v3.5.1

# Define software versions.
ARG FILEBOT_VERSION=4.8.2
ARG OPENJFX_VERSION=8.151.12-r0

# Define software download URLs.
ARG FILEBOT_URL=https://get.filebot.net/filebot/FileBot_${FILEBOT_VERSION}/FileBot_${FILEBOT_VERSION}-portable.tar.xz
ARG OPENJFX_URL=https://github.com/sgerrand/alpine-pkg-java-openjfx/releases/download/${OPENJFX_VERSION}/java-openjfx-${OPENJFX_VERSION}.apk

# Define working directory.
WORKDIR /tmp

# Install FileBot
RUN \
    add-pkg --virtual build-dependencies curl && \
    mkdir filebot && \
    # Download sources.
    curl -# -L ${FILEBOT_URL} | tar xJ -C filebot && \
    # Temporary hack until the official 4.8.4 release is available: do not use
    # the packaged jar, but the one containing the deadlock fix.
    rm filebot/jar/filebot.jar && \
    # Install.
    mkdir /opt/filebot && \
    cp -Rv filebot/jar /opt/filebot/ && \
    # Cleanup.
    del-pkg build-dependencies && \
    rm -rf /tmp/* /tmp/.[!.]*

# Temporary hack until the official 4.8.4 release is available.
COPY filebot-4.8.4-r5846.jar /opt/filebot/jar/filebot.jar

# Install dependencies.
RUN \
    add-pkg --virtual build-dependencies curl && \
    # OpenJFX
    curl -# -L -o java-openjfx.apk ${OPENJFX_URL} && \
    apk --no-cache add --allow-untrusted ./java-openjfx.apk && \
    add-pkg \
        gtk+2.0 \
        openjdk8-jre \
        java-jna \
        libmediainfo \
        && \
    # AcousItD (fpcalc)
    add-pkg chromaprint --repository http://dl-cdn.alpinelinux.org/alpine/edge/testing && \
    # YAD
    add-pkg yad && \
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

# Set environment variables.
ENV APP_NAME="FileBot"

# Define mountable directories.
VOLUME ["/config"]
VOLUME ["/storage"]

# Metadata.
LABEL \
      org.label-schema.name="filebot" \
      org.label-schema.description="Docker container for FileBot" \
      org.label-schema.version="unknown" \
      org.label-schema.vcs-url="https://github.com/jlesage/docker-filebot" \
      org.label-schema.schema-version="1.0"
