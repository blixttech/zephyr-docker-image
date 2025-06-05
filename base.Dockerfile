FROM ubuntu:24.04

ARG UID=1000
ARG GID=1000
ARG USER=user

ARG PYTHON_VENV_PATH=/opt/python/venv

ARG LLVM_VERSION=20
ARG SPARSE_VERSION=9212270048c3bd23f56c20a83d4f89b870b2b26e
ARG CPPCHECK_VERSION=2.17.1

ARG WGET_ARGS="-q --show-progress --progress=bar:force:noscroll"

# Set non-interactive frontend for apt-get to skip any user confirmations
ENV DEBIAN_FRONTEND=noninteractive

# This conflicts with uid 1000, remove it
RUN userdel -r ubuntu || true

# Set default shell during Docker image build to bash
SHELL ["/bin/bash", "-c"]

RUN apt-get -y update && \
    apt-get -y upgrade && \
    apt-get install --no-install-recommends -y \
    software-properties-common \
    lsb-release \
    bash \
    sudo \
    gosu \
    file \
    wget \
    gnupg \
    git \
    build-essential \
    automake \
    libpcre3-dev \
    device-tree-compiler \
    python3-pip \
    python3-venv \
    python3-dev \
    srecord \
    cppcheck \
    ccache

# Install Kitware CMake and ninja-build
RUN wget -O - https://apt.kitware.com/keys/kitware-archive-latest.asc 2>/dev/null \
    | gpg --dearmor -o /usr/share/keyrings/kitware-archive-keyring.gpg && \
    echo "deb [signed-by=/usr/share/keyrings/kitware-archive-keyring.gpg] https://apt.kitware.com/ubuntu/ $(lsb_release -cs) main" \
    | tee /etc/apt/sources.list.d/kitware.list

RUN apt-get update && \
    apt-get install -y \
    cmake \
    ninja-build

# Install LLVM and Clang
RUN wget ${WGET_ARGS} https://apt.llvm.org/llvm.sh && \
    chmod +x llvm.sh && \
    ./llvm.sh ${LLVM_VERSION} all && \
    rm -f llvm.sh && \
    update-alternatives --install /usr/bin/clang clang /usr/lib/llvm-${LLVM_VERSION}/bin/clang ${LLVM_VERSION}0 && \
    update-alternatives --install /usr/bin/clang++ clang++ /usr/lib/llvm-${LLVM_VERSION}/bin/clang++ ${LLVM_VERSION}0 && \
    update-alternatives --install /usr/bin/clangd clangd /usr/lib/llvm-${LLVM_VERSION}/bin/clangd ${LLVM_VERSION}0 && \
    update-alternatives --install /usr/bin/clang-format clang-format /usr/lib/llvm-${LLVM_VERSION}/bin/clang-format ${LLVM_VERSION}0 && \
    update-alternatives --install /usr/bin/clang-tidy clang-tidy /usr/lib/llvm-${LLVM_VERSION}/bin/clang-tidy ${LLVM_VERSION}0 && \
    update-alternatives --install /usr/bin/clang-check clang-check /usr/lib/llvm-${LLVM_VERSION}/bin/clang-check ${LLVM_VERSION}0 && \
    update-alternatives --install /usr/bin/clang-query clang-query /usr/lib/llvm-${LLVM_VERSION}/bin/clang-query ${LLVM_VERSION}0 && \
    update-alternatives --install /usr/bin/clang-apply-replacements clang-apply-replacements /usr/lib/llvm-${LLVM_VERSION}/bin/clang-apply-replacements ${LLVM_VERSION}0 && \
    update-alternatives --install /usr/bin/scan-build scan-build /usr/bin/scan-build-${LLVM_VERSION} ${LLVM_VERSION}0 && \
    update-alternatives --install /usr/bin/analyze-build analyze-build /usr/bin/analyze-build-${LLVM_VERSION} ${LLVM_VERSION}0

# Install sparse package for static analysis
RUN mkdir -p /opt/sparse && \
    cd /opt/sparse && \
    git clone https://git.kernel.org/pub/scm/devel/sparse/sparse.git && \
    cd sparse && git checkout ${SPARSE_VERSION} && \
    make -j8 && \
    PREFIX=/usr/local make install && \
    rm -rf /opt/sparse

# Install Python virtual environment
RUN mkdir -p ${PYTHON_VENV_PATH} && \
    python3 -m venv ${PYTHON_VENV_PATH}

ENV PATH=${PYTHON_VENV_PATH}/bin:$PATH

# Upgrade Python package install/build tools
RUN cd ${PYTHON_VENV_PATH}/bin && \
    pip install --no-cache-dir --upgrade pip setuptools wheel

# Install Python dependencies
RUN pip3 install --no-cache-dir \
    -r https://raw.githubusercontent.com/zephyrproject-rtos/zephyr/main/scripts/requirements.txt \
    -r https://raw.githubusercontent.com/zephyrproject-rtos/mcuboot/main/scripts/requirements.txt \
    GitPython \
    imgtool \
    junitparser \
    junit2html \
    numpy \
    protobuf \
    grpcio-tools \
    PyGithub \
    pylint \
    sh \
    statistics \
    codechecker \
    west

# Clean up stale packages
RUN apt-get clean -y && \
    apt-get autoremove --purge -y && \
    rm -rf /var/lib/apt/lists/*

# Create default account
RUN groupadd -g ${GID} -o ${USER} \
    && useradd -u ${UID} -m -g ${USER} -G plugdev ${USER} \
    && echo "${USER} ALL = NOPASSWD: ALL" > /etc/sudoers.d/${USER} \
    && chmod 0440 /etc/sudoers.d/${USER}

COPY entrypoint.sh /

ENTRYPOINT ["/entrypoint.sh"]

CMD ["/bin/bash"]