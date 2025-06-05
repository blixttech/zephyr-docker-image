# Zephyr Docker Image
This repository provides following docker images for development and CI/CD workflows.
* **zephyr-base:** Contains only the software needed for basic development without any toolchain.
* **zephyr-arm-zephyr-eabi:** Built on top of **zephyr-base** and contains GNU ARM Embedded Toolchain bundled with [Zephyr SDK](https://github.com/zephyrproject-rtos/sdk-ng).

## Usage

The pre-built docker images are available on GitHub Container Registry (ghcr.io).
Following commands demonstrate how to use the **zephyr-arm-zephyr-eabi** image for development tasks.  

```bash
cd <zephyr project/source directory>
docker run --rm -it \
    -e WORK_DIR="$(pwd -P)" \
    -e PUID="$(id -u)" \
    -e PGID="$(id -g)" \
    -v "$(pwd -P)":"$(pwd -P)" \
    ghcr.io/blixttech/zephyr-arm-zephyr-eabi:latest
```

The `docker run` command creates a container and mounts the current directory under the same path.
The [entrypoint](./entrypoint.sh) of the container does the followings.

* Set the user/group IDs of the internal user if they differ from `PUID` and `PGID`.
* Change the current working directory to `WORK_DIR`.
* Execute default command i.e. `/bin/bash` or the one specified as the internal user.

This setup simplifies the development process since files generated during the build process and their permissions are same as the host system.

## Build Images Locally

Use the following command to build all images locally.

```bash
make
```
