# Docker container for FileBot
[![Docker Image Size](https://img.shields.io/docker/image-size/jlesage/filebot/latest)](https://hub.docker.com/r/jlesage/filebot/tags) [![Build Status](https://github.com/jlesage/docker-filebot/actions/workflows/build-image.yml/badge.svg?branch=master)](https://github.com/jlesage/docker-filebot/actions/workflows/build-image.yml) [![GitHub Release](https://img.shields.io/github/release/jlesage/docker-filebot.svg)](https://github.com/jlesage/docker-filebot/releases/latest) [![Donate](https://img.shields.io/badge/Donate-PayPal-green.svg)](https://paypal.me/JocelynLeSage)

This is a Docker container for [FileBot](https://www.filebot.net).

The GUI of the application is accessed through a modern web browser (no
installation or configuration needed on the client side) or via any VNC client.

---

[![FileBot logo](https://images.weserv.nl/?url=raw.githubusercontent.com/jlesage/docker-templates/master/jlesage/images/filebot-icon.png&w=200)](https://www.filebot.net)[![FileBot](https://images.placeholders.dev/?width=224&height=110&fontFamily=Georgia,sans-serif&fontWeight=400&fontSize=52&text=FileBot&bgColor=rgba(0,0,0,0.0)&textColor=rgba(121,121,121,1))](https://www.filebot.net)

FileBot is the ultimate tool for organizing and renaming your movies, tv shows
or anime, and music well as downloading subtitles and artwork. It's smart and
just works.

---

## Quick Start

**NOTE**: The Docker command provided in this quick start is given as an example
and parameters should be adjusted to your need.

Launch the FileBot docker container with the following command:
```shell
docker run -d \
    --name=filebot \
    -p 5800:5800 \
    -v /docker/appdata/filebot:/config:rw \
    -v $HOME:/storage:rw \
    jlesage/filebot
```

Where:
  - `/docker/appdata/filebot`: This is where the application stores its configuration, states, log and any files needing persistency.
  - `$HOME`: This location contains files from your host that need to be accessible to the application.

Browse to `http://your-host-ip:5800` to access the FileBot GUI.
Files from the host appear under the `/storage` folder in the container.

## Documentation

Full documentation is available at https://github.com/jlesage/docker-filebot.

## Support or Contact

Having troubles with the container or have questions?  Please
[create a new issue].

For other great Dockerized applications, see https://jlesage.github.io/docker-apps.

[create a new issue]: https://github.com/jlesage/docker-filebot/issues
