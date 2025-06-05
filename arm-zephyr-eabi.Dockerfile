ARG BASE_IMAGE=zephyr-base:latest

FROM ${BASE_IMAGE}

ARG ZSDK_VERSION=0.17.0

ARG WGET_ARGS="-q --show-progress --progress=bar:force:noscroll"

# Install Zephyr SDK
RUN mkdir -p /opt/toolchains && \
	cd /opt/toolchains && \
	wget ${WGET_ARGS} https://github.com/zephyrproject-rtos/sdk-ng/releases/download/v${ZSDK_VERSION}/zephyr-sdk-${ZSDK_VERSION}_linux-x86_64_minimal.tar.xz && \
	tar xf zephyr-sdk-${ZSDK_VERSION}_linux-x86_64_minimal.tar.xz && \
	zephyr-sdk-${ZSDK_VERSION}/setup.sh -t arm-zephyr-eabi -h && \
	rm zephyr-sdk-${ZSDK_VERSION}_linux-x86_64_minimal.tar.xz

ENV ZEPHYR_TOOLCHAIN_VARIANT=zephyr
ENV ZEPHYR_SDK_INSTALL_DIR=/opt/toolchains/zephyr-sdk-${ZSDK_VERSION}
