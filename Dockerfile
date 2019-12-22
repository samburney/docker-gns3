FROM lsiobase/ubuntu:bionic

LABEL maintainer='Sam Burney <sam@burney.io>'

# Disable dpkg frontend to avoid error messages
ENV DEBIAN_FRONTEND="noninteractive"

# Package lists
ARG PACKAGES="qemu-kvm libvirt-bin virtinst bridge-utils cpu-checker python3-pip sudo"
ARG BUILD_PACKAGES="build-essential git libpthread-stubs0-dev libpcap-dev cmake libelf-dev wget"

# Install packages
RUN apt -y update \
    && apt -y install ${PACKAGES} \
    && apt -y install ${BUILD_PACKAGES} \
    && wget -O - https://get.docker.io | sh

# Get sources
RUN git clone git://github.com/GNS3/dynamips.git /usr/src/dynamips \
    && git clone https://github.com/GNS3/ubridge.git /usr/src/ubridge \
    && git clone https://github.com/GNS3/gns3-server.git /usr/src/gns3-server

# Build sources
## ubridge
RUN cd /usr/src/ubridge \
    && make \
    && make install

## dynamips
RUN mkdir /usr/src/dynamips/build \
    && cd /usr/src/dynamips/build \
    && cmake .. -DDYNAMIPS_CODE=stable \
    && make install

## gns3-server
RUN cd /usr/src/gns3-server \
    && python3 setup.py install

# Remove packages only required for the build
RUN apt -y remove --purge ${BUILD_PACKAGES} \
    && apt -y autoremove --purge \
    && apt clean \
    && rm -rf /var/lib/apt/lists/*

# Copy required files
ADD root/ /
