#
# filebot Dockerfile
#
# https://github.com/jlesage/docker-filebot
#

# Pull base image.
FROM jlesage/baseimage-gui:alpine-3.11-v3.5.3

# Docker image version is provided via build arg.
ARG DOCKER_IMAGE_VERSION=unknown

# Define software versions.
ARG FILEBOT_VERSION=4.9.0
ARG OPENJDK_VERSION=11.0.6
ARG JAVAFX_VERSION=13+14
ARG GRADLE_VERSION=5.3
ARG ZULU_OPENJDK_VERSION=11.37.17
ARG CHROMAPRINT_VERSION=1.4.3

# Define software download URLs.
ARG FILEBOT_URL=https://get.filebot.net/filebot/FileBot_${FILEBOT_VERSION}/FileBot_${FILEBOT_VERSION}-portable.tar.xz
ARG OPENJDK_URL=https://cdn.azul.com/zulu/bin/zulu${ZULU_OPENJDK_VERSION}-ca-jdk${OPENJDK_VERSION}-linux_musl_x64.tar.gz
ARG JAVAFX_URL=https://github.com/openjdk/jfx/archive/${JAVAFX_VERSION}.tar.gz
ARG GRADLE_URL=https://services.gradle.org/distributions/gradle-${GRADLE_VERSION}-bin.zip
ARG CHROMAPRINT_URL=https://github.com/acoustid/chromaprint/archive/v${CHROMAPRINT_VERSION}.tar.gz

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

# Build custom Java runtime image.
RUN \
    add-pkg --virtual build-dependencies \
        curl \
        && \
    mkdir /tmp/jdk/ && \
    # Download and extract OpenJDK.
    echo "Downloading OpenJDK..." && \
    curl -# -L "${OPENJDK_URL}" | tar xz --strip 1 -C /tmp/jdk && \
    # Extract Java module dependencies.
    for JAR in /opt/filebot/jar/*.jar; do \
        echo "Getting dependencies of $JAR..."; \
        /tmp/jdk/bin/jdeps $JAR 2>/dev/null | grep -v $(basename $JAR) | grep -v 'JDK internal API' | grep -v 'not found' | awk '{ print $4 }'| sort -u >> /tmp/jdeps; \
    done && \
    echo jdk.crypto.ec >> /tmp/jdeps && \
    echo jdk.zipfs >> /tmp/jdeps && \
    echo jdk.unsupported >> /tmp/jdeps && \
    echo jdk.unsupported.desktop >> /tmp/jdeps && \
    echo jdk.xml.dom >> /tmp/jdeps && \
    # Create a minimal Java install.
    /tmp/jdk/bin/jlink \
        --compress=2 \
        --module-path /tmp/jdk/jmods \
        --add-modules "$(cat /tmp/jdeps | sort -u | tr '\n' ',')" \
        --output /opt/filebot/jre \
        && \
    # Cleanup.
    del-pkg build-dependencies && \
    rm -rf /tmp/* /tmp/.[!.]*

# Build JavaFX.
# NOTE: Ideally, we would use JavaFX integrated with OpenJDK.  However, there
#       is no such integration for Alpine yet.
RUN \
    add-pkg --virtual build-dependencies \
        curl \
        patch \
        build-base \
        apache-ant \
        pkgconf \
        gtk+2.0-dev \
        gtk+3.0-dev \
        libxtst-dev \
        && \
    # Download and extract OpenJDK.
    echo "Downloading OpenJDK..." && \
    mkdir /tmp/jdk && \
    curl -# -L "${OPENJDK_URL}" | tar xz --strip 1 -C /tmp/jdk && \
    # Download and extract JavaFX.
    echo "Downloading JavaFX..." && \
    mkdir /tmp/jfx && \
    curl -# -L "${JAVAFX_URL}" | tar xz --strip 1 -C /tmp/jfx && \
    # Download and extract gradle.
    echo "Downloading gradle..." && \
    curl -# -L -o gradle.zip "${GRADLE_URL}" && \
    unzip gradle.zip && \
    # Patch.
    sed-patch '/-fstack-protector/a "-Wno-deprecated-declarations",' jfx/buildSrc/linux.gradle && \
    curl -# -L -o fix.patch https://raw.githubusercontent.com/sgerrand/alpine-pkg-java-openjfx/master/04-fix-gcc-sentinel-warnings.patch && \
    sed-patch 's/graphics/javafx.graphics/g' fix.patch && \
    patch -d jfx -p1 < fix.patch && \
    # Build.
    cd jfx && \
    export JAVA_HOME=/tmp/jdk && \
    export JDK_HOME=/tmp/jdk && \
    export PATH="$PATH:$JAVA_HOME/bin" && \
    /tmp/gradle-5.3/bin/gradle --no-daemon && \
    cd .. && \
    # Install.
    cp -r jfx/build/sdk/lib /opt/filebot/jfx && \
    rm /opt/filebot/jfx/libglassgtk2.so \
       /opt/filebot/jfx/src.zip \
       && \
    strip /opt/filebot/jfx/*.so && \
    # Cleanup.
    del-pkg build-dependencies && \
    rm -r /root/.gradle && \
    rm -r /root/.java && \
    rm -rf /tmp/* /tmp/.[!.]*

# Install Java JNA.
# Note that we only need the .so library.
RUN \
    add-pkg --repository http://dl-cdn.alpinelinux.org/alpine/edge/main \
            --repository http://dl-cdn.alpinelinux.org/alpine/edge/community \
            --virtual build-dependencies \
            java-jna-native && \
    cp -a /usr/lib/libjnidispatch.so /usr/lib/libjnidispatch.so.bk && \
    cp -a /usr/lib/libjnidispatch.so.5.1.0 /usr/lib/libjnidispatch.so.5.1.0.bk && \
    # Cleanup.
    del-pkg build-dependencies && \
    rm -rf /tmp/* /tmp/.[!.]* && \
    # Restore library.
    mv /usr/lib/libjnidispatch.so.bk /usr/lib/libjnidispatch.so && \
    mv /usr/lib/libjnidispatch.so.5.1.0.bk /usr/lib/libjnidispatch.so.5.1.0

# Install dependencies.
RUN \
    add-pkg --virtual build-dependencies curl && \
    add-pkg \
        p7zip \
        unrar \
        findutils \
        coreutils \
        nss \
        libmediainfo \
        ffmpeg \
        yad \
        && \
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
    rmdir /usr/include && \
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
    AMC_INPUT_FOLDER=/watch \
    AMC_OUTPUT_FOLDER=/output

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
