# Docker container for FileBot
[![Docker Image Size](https://img.shields.io/docker/image-size/jlesage/filebot/latest)](https://hub.docker.com/r/jlesage/filebot/tags) [![Build Status](https://drone.le-sage.com/api/badges/jlesage/docker-filebot/status.svg)](https://drone.le-sage.com/jlesage/docker-filebot) [![GitHub Release](https://img.shields.io/github/release/jlesage/docker-filebot.svg)](https://github.com/jlesage/docker-filebot/releases/latest) [![Donate](https://img.shields.io/badge/Donate-PayPal-green.svg)](https://paypal.me/JocelynLeSage/0usd)

This is a Docker container for [FileBot](http://www.filebot.net/).

The GUI of the application is accessed through a modern web browser (no installation or configuration needed on the client side) or via any VNC client.

---

[![FileBot logo](https://images.weserv.nl/?url=raw.githubusercontent.com/jlesage/docker-templates/master/jlesage/images/filebot-icon.png&w=200)](http://www.filebot.net/)[![FileBot](https://dummyimage.com/400x110/ffffff/575757&text=FileBot)](http://www.filebot.net/)

FileBot is the ultimate tool for organizing and renaming your movies, tv shows
or anime, and music well as downloading subtitles and artwork. It's smart and
just works.

---

## Table of Content

   * [Docker container for FileBot](#docker-container-for-filebot)
      * [Table of Content](#table-of-content)
      * [Quick Start](#quick-start)
      * [Usage](#usage)
         * [Environment Variables](#environment-variables)
         * [Data Volumes](#data-volumes)
         * [Ports](#ports)
         * [Changing Parameters of a Running Container](#changing-parameters-of-a-running-container)
      * [Docker Compose File](#docker-compose-file)
      * [Docker Image Update](#docker-image-update)
         * [Synology](#synology)
         * [unRAID](#unraid)
      * [User/Group IDs](#usergroup-ids)
      * [Accessing the GUI](#accessing-the-gui)
      * [Security](#security)
         * [SSVNC](#ssvnc)
         * [Certificates](#certificates)
         * [VNC Password](#vnc-password)
      * [Reverse Proxy](#reverse-proxy)
         * [Routing Based on Hostname](#routing-based-on-hostname)
         * [Routing Based on URL Path](#routing-based-on-url-path)
      * [Shell Access](#shell-access)
      * [License](#license)
         * [Installing a License](#installing-a-license)
         * [Donation Supported Version](#donation-supported-version)
      * [Automated Media Center (AMC)](#automated-media-center-amc)
      * [Using a Beta Version](#using-a-beta-version)
      * [Support or Contact](#support-or-contact)

## Quick Start

**NOTE**: The Docker command provided in this quick start is given as an example
and parameters should be adjusted to your need.

Launch the FileBot docker container with the following command:
```
docker run -d \
    --name=filebot \
    -p 5800:5800 \
    -v /docker/appdata/filebot:/config:rw \
    -v $HOME:/storage:rw \
    jlesage/filebot
```

Where:
  - `/docker/appdata/filebot`: This is where the application stores its configuration, log and any files needing persistency.
  - `$HOME`: This location contains files from your host that need to be accessible by the application.

Browse to `http://your-host-ip:5800` to access the FileBot GUI.
Files from the host appear under the `/storage` folder in the container.

## Usage

```
docker run [-d] \
    --name=filebot \
    [-e <VARIABLE_NAME>=<VALUE>]... \
    [-v <HOST_DIR>:<CONTAINER_DIR>[:PERMISSIONS]]... \
    [-p <HOST_PORT>:<CONTAINER_PORT>]... \
    jlesage/filebot
```
| Parameter | Description |
|-----------|-------------|
| -d        | Run the container in the background.  If not set, the container runs in the foreground. |
| -e        | Pass an environment variable to the container.  See the [Environment Variables](#environment-variables) section for more details. |
| -v        | Set a volume mapping (allows to share a folder/file between the host and the container).  See the [Data Volumes](#data-volumes) section for more details. |
| -p        | Set a network port mapping (exposes an internal container port to the host).  See the [Ports](#ports) section for more details. |

### Environment Variables

To customize some properties of the container, the following environment
variables can be passed via the `-e` parameter (one for each variable).  Value
of this parameter has the format `<VARIABLE_NAME>=<VALUE>`.

| Variable       | Description                                  | Default |
|----------------|----------------------------------------------|---------|
|`USER_ID`| ID of the user the application runs as.  See [User/Group IDs](#usergroup-ids) to better understand when this should be set. | `1000` |
|`GROUP_ID`| ID of the group the application runs as.  See [User/Group IDs](#usergroup-ids) to better understand when this should be set. | `1000` |
|`SUP_GROUP_IDS`| Comma-separated list of supplementary group IDs of the application. | (unset) |
|`UMASK`| Mask that controls how file permissions are set for newly created files. The value of the mask is in octal notation.  By default, this variable is not set and the default umask of `022` is used, meaning that newly created files are readable by everyone, but only writable by the owner. See the following online umask calculator: http://wintelguy.com/umask-calc.pl | (unset) |
|`TZ`| [TimeZone] of the container.  Timezone can also be set by mapping `/etc/localtime` between the host and the container. | `Etc/UTC` |
|`KEEP_APP_RUNNING`| When set to `1`, the application will be automatically restarted if it crashes or if a user quits it. | `0` |
|`APP_NICENESS`| Priority at which the application should run.  A niceness value of -20 is the highest priority and 19 is the lowest priority.  By default, niceness is not set, meaning that the default niceness of 0 is used.  **NOTE**: A negative niceness (priority increase) requires additional permissions.  In this case, the container should be run with the docker option `--cap-add=SYS_NICE`. | (unset) |
|`CLEAN_TMP_DIR`| When set to `1`, all files in the `/tmp` directory are deleted during the container startup. | `1` |
|`DISPLAY_WIDTH`| Width (in pixels) of the application's window. | `1280` |
|`DISPLAY_HEIGHT`| Height (in pixels) of the application's window. | `768` |
|`SECURE_CONNECTION`| When set to `1`, an encrypted connection is used to access the application's GUI (either via a web browser or VNC client).  See the [Security](#security) section for more details. | `0` |
|`VNC_PASSWORD`| Password needed to connect to the application's GUI.  See the [VNC Password](#vnc-password) section for more details. | (unset) |
|`X11VNC_EXTRA_OPTS`| Extra options to pass to the x11vnc server running in the Docker container.  **WARNING**: For advanced users. Do not use unless you know what you are doing. | (unset) |
|`ENABLE_CJK_FONT`| When set to `1`, open-source computer font `WenQuanYi Zen Hei` is installed.  This font contains a large range of Chinese/Japanese/Korean characters. | `0` |
|`OPENSUBTITLES_USERNAME`| Username of your [OpenSubtitles](https://www.opensubtitles.org) account.  Required to download subtitles. | (unset) |
|`OPENSUBTITLES_PASSWORD`| Password of your [OpenSubtitles](https://www.opensubtitles.org) account.  Required to download subtitles. | (unset) |
|`FILEBOT_CUSTOM_OPTIONS`| Custom arguments to pass to FileBot.  This applies to the UI only. | (unset) |
|`USE_FILEBOT_BETA`| When set to `1`, FileBot installed under `/config/beta` (container path) is used.  If no FileBot installation is found under this folder, the latest beta version is automatically downloaded during container startup.  See [Using a Beta Version](#using-a-beta-version) section for more details.  **NOTE**: Use at your own risk.  Beta version may have bugs and stability issues. | `0` |
|`AMC_INTERVAL`| Time (in seconds) between each invocation of the Automated Media Center (AMC) script. | `1800` |
|`AMC_INPUT_STABLE_TIME`| Time (in seconds) during which properties (e.g. size, time, etc) of files in the watch folder need to remain the same before invoking the Automated Media Center (AMC) script.  This is to avoid processing the watch folder while files are being copied. | `10` |
|`AMC_ACTION`| Action performed by the Automated Media Center (AMC) script on files.  Valid values are `test`, `copy`, `move`, `symlink`, `hardlink`, `keeplink`, `duplicate` or `clone`.  Use the `test` operation to perform a dry-run and verify that everything gets matched up correctly. | `test` |
|`AMC_CONFLICT`| Conflict resolution strategy used by the Automated Media Center (AMC) script: `skip` never overrides existing files, while `auto` overrides existing file only if new media is better. | `auto` |
|`AMC_MATCH_MODE`| Match mode used by the Automated Media Center (AMC) script: `opportunistic` mode works for all files regardless how badly they are named, while `strict` mode works for reasonably well-named files and ignore files that cannot be matched accurately.  See [Match Mode](https://www.filebot.net/forums/viewtopic.php?t=4695) for complete documentation. | `opportunistic` |
|`AMC_ARTWORK`| When set to `y`, artwork is fetched and NFO file is generated by the Automated Media Center (AMC) script. | `n` |
|`AMC_LANG`| Language used by the Automated Media Center (AMC) script to rename files.  Two-characters language code or value like English, French, German, Chinese, etc can be used. | `English` |
|`AMC_MUSIC_FORMAT`| Define how music files are renamed by the Automated Media Center (AMC) script.  Filebot supports a very powerful naming scheme.  See [Format Expressions](https://www.filebot.net/naming.html) for complete documentation. | `{plex}` |
|`AMC_MOVIE_FORMAT`| Define how movie files are renamed by the Automated Media Center (AMC) script.  Filebot supports a very powerful naming scheme.  See [Format Expressions](https://www.filebot.net/naming.html) for complete documentation. | `{plex}` |
|`AMC_SERIES_FORMAT`| Define how TV series files are renamed by the Automated Media Center (AMC) script.  Filebot supports a very powerful naming scheme.  See [Format Expressions](https://www.filebot.net/naming.html) for complete documentation. | `{plex}` |
|`AMC_ANIME_FORMAT`| Define how anime files are renamed by the Automated Media Center (AMC) script.  Filebot supports a very powerful naming scheme.  See [Format Expressions](https://www.filebot.net/naming.html) for complete documentation. | `{plex}` |
|`AMC_PROCESS_MUSIC`| When set to `y`, music files are processed by the Automated Media Center (AMC) script.  A value of `n` does not process them. | `y` |
|`AMC_SUBTITLE_LANG`| Comma-separated list of subtitle languages to download.  Example: `en,de,fr`. | (unset) |
|`AMC_CUSTOM_OPTIONS`| Custom arguments to pass to the Automated Media Center (AMC) script. | (unset) |
|`AMC_INPUT_DIR`| Directory inside the container used as the input folder of the Automated Media Center (AMC) script. | `/watch` |
|`AMC_OUTPUT_DIR`| Directory inside the container used as the output folder of the Automated Media Center (AMC) script. | `/output` |
|`AMC_INSTALL_PKGS`| Space-separated list of Alpine Linux packages to install.  This is useful when the Automated Media Center (AMC) script is configured to invoke a user-defined script that requires tools not available in the container image.  See https://pkgs.alpinelinux.org/packages?name=&branch=v3.15&arch=x86_64 for the list of available Alpine Linux packages. | (unset) |

### Data Volumes

The following table describes data volumes used by the container.  The mappings
are set via the `-v` parameter.  Each mapping is specified with the following
format: `<HOST_DIR>:<CONTAINER_DIR>[:PERMISSIONS]`.

| Container path  | Permissions | Description |
|-----------------|-------------|-------------|
|`/config`| rw | This is where the application stores its configuration, log and any files needing persistency. |
|`/storage`| rw | This location contains files from your host that need to be accessible by the application. |
|`/watch`| rw | This is the input folder of the Automated Media Center (AMC) script.  Any media copied to this folder will be processed by the script.  Note that there is no need to map this folder if the script is not used. |
|`/output`| rw | This is the output folder of the Automated Media Center (AMC) script.  This is where medias are located once they are renamed and organized.  Note that there is no need to map this folder if the script is not used. |

### Ports

Here is the list of ports used by the container.  They can be mapped to the host
via the `-p` parameter (one per port mapping).  Each mapping is defined in the
following format: `<HOST_PORT>:<CONTAINER_PORT>`.  The port number inside the
container cannot be changed, but you are free to use any port on the host side.

| Port | Mapping to host | Description |
|------|-----------------|-------------|
| 5800 | Mandatory | Port used to access the application's GUI via the web interface. |
| 5900 | Optional | Port used to access the application's GUI via the VNC protocol.  Optional if no VNC client is used. |

### Changing Parameters of a Running Container

As can be seen, environment variables, volume and port mappings are all specified
while creating the container.

The following steps describe the method used to add, remove or update
parameter(s) of an existing container.  The general idea is to destroy and
re-create the container:

  1. Stop the container (if it is running):
```
docker stop filebot
```
  2. Remove the container:
```
docker rm filebot
```
  3. Create/start the container using the `docker run` command, by adjusting
     parameters as needed.

**NOTE**: Since all application's data is saved under the `/config` container
folder, destroying and re-creating a container is not a problem: nothing is lost
and the application comes back with the same state (as long as the mapping of
the `/config` folder remains the same).

## Docker Compose File

Here is an example of a `docker-compose.yml` file that can be used with
[Docker Compose](https://docs.docker.com/compose/overview/).

Make sure to adjust according to your needs.  Note that only mandatory network
ports are part of the example.

```yaml
version: '3'
services:
  filebot:
    image: jlesage/filebot
    ports:
      - "5800:5800"
    volumes:
      - "/docker/appdata/filebot:/config:rw"
      - "$HOME:/storage:rw"
```

## Docker Image Update

Because features are added, issues are fixed, or simply because a new version
of the containerized application is integrated, the Docker image is regularly
updated.  Different methods can be used to update the Docker image.

The system used to run the container may have a built-in way to update
containers.  If so, this could be your primary way to update Docker images.

An other way is to have the image be automatically updated with [Watchtower].
Watchtower is a container-based solution for automating Docker image updates.
This is a "set and forget" type of solution: once a new image is available,
Watchtower will seamlessly perform the necessary steps to update the container.

Finally, the Docker image can be manually updated with these steps:

  1. Fetch the latest image:
```
docker pull jlesage/filebot
```
  2. Stop the container:
```
docker stop filebot
```
  3. Remove the container:
```
docker rm filebot
```
  4. Create and start the container using the `docker run` command, with the
the same parameters that were used when it was deployed initially.

[Watchtower]: https://github.com/containrrr/watchtower

### Synology

For owners of a Synology NAS, the following steps can be used to update a
container image.

  1.  Open the *Docker* application.
  2.  Click on *Registry* in the left pane.
  3.  In the search bar, type the name of the container (`jlesage/filebot`).
  4.  Select the image, click *Download* and then choose the `latest` tag.
  5.  Wait for the download to complete.  A  notification will appear once done.
  6.  Click on *Container* in the left pane.
  7.  Select your FileBot container.
  8.  Stop it by clicking *Action*->*Stop*.
  9.  Clear the container by clicking *Action*->*Reset* (or *Action*->*Clear* if
      you don't have the latest *Docker* application).  This removes the
      container while keeping its configuration.
  10. Start the container again by clicking *Action*->*Start*. **NOTE**:  The
      container may temporarily disappear from the list while it is re-created.

### unRAID

For unRAID, a container image can be updated by following these steps:

  1. Select the *Docker* tab.
  2. Click the *Check for Updates* button at the bottom of the page.
  3. Click the *update ready* link of the container to be updated.

## User/Group IDs

When using data volumes (`-v` flags), permissions issues can occur between the
host and the container.  For example, the user within the container may not
exist on the host.  This could prevent the host from properly accessing files
and folders on the shared volume.

To avoid any problem, you can specify the user the application should run as.

This is done by passing the user ID and group ID to the container via the
`USER_ID` and `GROUP_ID` environment variables.

To find the right IDs to use, issue the following command on the host, with the
user owning the data volume on the host:

    id <username>

Which gives an output like this one:
```
uid=1000(myuser) gid=1000(myuser) groups=1000(myuser),4(adm),24(cdrom),27(sudo),46(plugdev),113(lpadmin)
```

The value of `uid` (user ID) and `gid` (group ID) are the ones that you should
be given the container.

## Accessing the GUI

Assuming that container's ports are mapped to the same host's ports, the
graphical interface of the application can be accessed via:

  * A web browser:
```
http://<HOST IP ADDR>:5800
```

  * Any VNC client:
```
<HOST IP ADDR>:5900
```

## Security

By default, access to the application's GUI is done over an unencrypted
connection (HTTP or VNC).

Secure connection can be enabled via the `SECURE_CONNECTION` environment
variable.  See the [Environment Variables](#environment-variables) section for
more details on how to set an environment variable.

When enabled, application's GUI is performed over an HTTPs connection when
accessed with a browser.  All HTTP accesses are automatically redirected to
HTTPs.

When using a VNC client, the VNC connection is performed over SSL.  Note that
few VNC clients support this method.  [SSVNC] is one of them.

[SSVNC]: http://www.karlrunge.com/x11vnc/ssvnc.html

### SSVNC

[SSVNC] is a VNC viewer that adds encryption security to VNC connections.

While the Linux version of [SSVNC] works well, the Windows version has some
issues.  At the time of writing, the latest version `1.0.30` is not functional,
as a connection fails with the following error:
```
ReadExact: Socket error while reading
```
However, for your convenience, an unofficial and working version is provided
here:

https://github.com/jlesage/docker-baseimage-gui/raw/master/tools/ssvnc_windows_only-1.0.30-r1.zip

The only difference with the official package is that the bundled version of
`stunnel` has been upgraded to version `5.49`, which fixes the connection
problems.

### Certificates

Here are the certificate files needed by the container.  By default, when they
are missing, self-signed certificates are generated and used.  All files have
PEM encoded, x509 certificates.

| Container Path                  | Purpose                    | Content |
|---------------------------------|----------------------------|---------|
|`/config/certs/vnc-server.pem`   |VNC connection encryption.  |VNC server's private key and certificate, bundled with any root and intermediate certificates.|
|`/config/certs/web-privkey.pem`  |HTTPs connection encryption.|Web server's private key.|
|`/config/certs/web-fullchain.pem`|HTTPs connection encryption.|Web server's certificate, bundled with any root and intermediate certificates.|

**NOTE**: To prevent any certificate validity warnings/errors from the browser
or VNC client, make sure to supply your own valid certificates.

**NOTE**: Certificate files are monitored and relevant daemons are automatically
restarted when changes are detected.

### VNC Password

To restrict access to your application, a password can be specified.  This can
be done via two methods:
  * By using the `VNC_PASSWORD` environment variable.
  * By creating a `.vncpass_clear` file at the root of the `/config` volume.
    This file should contain the password in clear-text.  During the container
    startup, content of the file is obfuscated and moved to `.vncpass`.

The level of security provided by the VNC password depends on two things:
  * The type of communication channel (encrypted/unencrypted).
  * How secure the access to the host is.

When using a VNC password, it is highly desirable to enable the secure
connection to prevent sending the password in clear over an unencrypted channel.

**ATTENTION**: Password is limited to 8 characters.  This limitation comes from
the Remote Framebuffer Protocol [RFC](https://tools.ietf.org/html/rfc6143) (see
section [7.2.2](https://tools.ietf.org/html/rfc6143#section-7.2.2)).  Any
characters beyond the limit are ignored.

## Reverse Proxy

The following sections contain NGINX configurations that need to be added in
order to reverse proxy to this container.

A reverse proxy server can route HTTP requests based on the hostname or the URL
path.

### Routing Based on Hostname

In this scenario, each hostname is routed to a different application/container.

For example, let's say the reverse proxy server is running on the same machine
as this container.  The server would proxy all HTTP requests sent to
`filebot.domain.tld` to the container at `127.0.0.1:5800`.

Here are the relevant configuration elements that would be added to the NGINX
configuration:

```
map $http_upgrade $connection_upgrade {
	default upgrade;
	''      close;
}

upstream docker-filebot {
	# If the reverse proxy server is not running on the same machine as the
	# Docker container, use the IP of the Docker host here.
	# Make sure to adjust the port according to how port 5800 of the
	# container has been mapped on the host.
	server 127.0.0.1:5800;
}

server {
	[...]

	server_name filebot.domain.tld;

	location / {
	        proxy_pass http://docker-filebot;
	}

	location /websockify {
		proxy_pass http://docker-filebot;
		proxy_http_version 1.1;
		proxy_set_header Upgrade $http_upgrade;
		proxy_set_header Connection $connection_upgrade;
		proxy_read_timeout 86400;
	}
}

```

### Routing Based on URL Path

In this scenario, the hostname is the same, but different URL paths are used to
route to different applications/containers.

For example, let's say the reverse proxy server is running on the same machine
as this container.  The server would proxy all HTTP requests for
`server.domain.tld/filebot` to the container at `127.0.0.1:5800`.

Here are the relevant configuration elements that would be added to the NGINX
configuration:

```
map $http_upgrade $connection_upgrade {
	default upgrade;
	''      close;
}

upstream docker-filebot {
	# If the reverse proxy server is not running on the same machine as the
	# Docker container, use the IP of the Docker host here.
	# Make sure to adjust the port according to how port 5800 of the
	# container has been mapped on the host.
	server 127.0.0.1:5800;
}

server {
	[...]

	location = /filebot {return 301 $scheme://$http_host/filebot/;}
	location /filebot/ {
		proxy_pass http://docker-filebot/;
		location /filebot/websockify {
			proxy_pass http://docker-filebot/websockify/;
			proxy_http_version 1.1;
			proxy_set_header Upgrade $http_upgrade;
			proxy_set_header Connection $connection_upgrade;
			proxy_read_timeout 86400;
		}
	}
}

```
## Shell Access

To get shell access to the running container, execute the following command:

```
docker exec -ti CONTAINER sh
```

Where `CONTAINER` is the ID or the name of the container used during its
creation (e.g. `crashplan-pro`).

## License

FileBot supports a cross-platform custom license model,
which means that a license can be purchased and then be used on all the buyer's
machines.

While FileBot can be used/evaluated without a license,
certain features, like renaming files, won't work without one.

A license can be purchased at https://www.filebot.net/purchase.html.

### Installing a License

Once purchased, the license file received via email can be saved on the host,
into the configuration directory of the container (i.e. in the directory mapped
to `/config`).

Then, start or restart the container to have it automatically installed.

**NOTE**: The license file is expected to have a `.psm` extension.

### Donation Supported Version

In the past, FileBot was donation supported, meaning that
the author was expecting users to donate an arbitrary amount of money if they
like and use the software.

The last version of FileBot supporting this model is
`4.7.9`.  This version is implemented in container image version `1.0.2`.

To revert to this version, create the container by using
`jlesage/filebot:v1.0.2` as the image name.

**NOTE**: While no license is required to use this version, it is no longer
supported and maintained by the author of FileBot.

## Automated Media Center (AMC)

This container supports the FileBot's
[Automated Media Center](https://www.filebot.net/forums/viewtopic.php?t=215)
(AMC) script.  This script automatically and smartly organizes movies, TV shows,
anime and music.

Basically, files copied to the `/watch` container folder are automatically
renamed and organized to the `/output` container folder.

Configuration of the AMC script is done via `AMC_*` environment variables. See
the [Environment Variables](#environment-variables) section for the list and
descriptions of environment variables that can be set.

To see what the AMC script is doing, look at the container's log.

**NOTE**: By default, the script runs in dry mode, meaning that no change is
performed.  This allows you to verify that results produced by the script are
correct.  Then, the `AMC_ACTION` environment variable can be updated to perform
changes to the file system.

**NOTE**: For the script to properly function, container folders `/watch` and
`/output` must be properly mapped to the host.  See the
[Data Volumes](#data-volumes) section.

## Using a Beta Version

This container provides the stable version of FileBot.
However, it's possible to use a beta version when needed.  This is done by
setting the environment variable `USE_FILEBOT_BETA` to `1`.

When set, the custom FileBot installation located under
`/config/beta` (container path) is used instead of the stable version.

FileBot beta version can be installed manually, by
downloading the portable version from https://get.filebot.net/filebot/BETA and
extracting the package to `/config/beta`.  Else, the latest beta version is
downloaded automatically during the startup of the container if no installation
is found under `/config/beta`.

**NOTE**: Beta version may have bugs and stability issues.  Use at your own
risk.

[TimeZone]: http://en.wikipedia.org/wiki/List_of_tz_database_time_zones

## Support or Contact

Having troubles with the container or have questions?  Please
[create a new issue].

For other great Dockerized applications, see https://jlesage.github.io/docker-apps.

[create a new issue]: https://github.com/jlesage/docker-filebot/issues
