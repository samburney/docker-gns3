FROM lsiobase/ubuntu:bionic

LABEL maintainer='Sam Burney <sam@burney.io>'

# Get GNS3_VERSION argument is set at built time
ARG GNS3_VERSION

# Disable dpkg frontend to avoid error messages
ENV DEBIAN_FRONTEND="noninteractive"

# Package lists
ARG PACKAGES="qemu-kvm libvirt-bin virtinst bridge-utils cpu-checker python3-pip sudo"
ARG BUILD_PACKAGES="build-essential git libpthread-stubs0-dev libpcap-dev cmake libelf-dev wget"

# Install packages
RUN apt -y update \
    && apt -y install ${PACKAGES} \
    && apt -y install ${BUILD_PACKAGES} \
    && wget -O - https://get.docker.io | sh \
    \
    # Get sources
    && git clone https://github.com/GNS3/ubridge.git /usr/src/ubridge \
    && git clone https://github.com/GNS3/dynamips.git /usr/src/dynamips \
    && git clone https://github.com/GNS3/gns3-server.git /usr/src/gns3-server \
    \
    # Build sources
    ## ubridge
    && cd /usr/src/ubridge \
    && make \
    && make install \
    \
    ## dynamips
    && mkdir /usr/src/dynamips/build \
    && cd /usr/src/dynamips/build \
    && cmake .. -DDYNAMIPS_CODE=stable \
    && make install \
    \
    ## gns3-server
    && cd /usr/src/gns3-server \
    && if [ -n "$GNS3_VERSION" -a "$GNS3_VERSION" != "master" ] ; then \
        git fetch --tags \
        && git checkout "$GNS3_VERSION" \
    ; fi \
    && python3 setup.py install \
    \
    # Clean up sources
    && rm -r /usr/src/ubridge \
    && rm -r /usr/src/dynamips \
    && rm -r /usr/src/gns3-server \
    \
    # Remove packages only required for the build
    && apt -y remove --purge ${BUILD_PACKAGES} \
    && apt -y autoremove --purge \
    && apt clean \
    && rm -rf /var/lib/apt/lists/*

# Copy required files
ADD root/ /
