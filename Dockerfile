FROM debian:jessie-slim
MAINTAINER Erik Rogers <erik.rogers@live.com>

ENV CREEP_MINER_VERSION 2.7.6
ENV CREEP_MINER_PACKAGE creepMiner-${CREEP_MINER_VERSION}
ENV CREEP_MINER_ARCHIVE ${CREEP_MINER_VERSION}.tar.gz

# Choose source release for CreepMiner
ENV CREEP_MINER_RELEASE https://github.com/Creepsky/creepMiner/archive/$CREEP_MINER_ARCHIVE
ENV CREEP_MINER_DIR /opt/creepMiner

# Install necessary dependencies for Poco
RUN apt-get update && apt-get upgrade -y && apt-get install -y \
  build-essential \
  libssl-dev \
  openssl \
  cmake \
  git \
  sudo \
  wget \
  && rm -rf /var/lib/apt/lists/*

# Download and build from source
WORKDIR /tmp
RUN wget $CREEP_MINER_RELEASE \
  && mkdir -p $CREEP_MINER_PACKAGE \
  && mkdir -p $CREEP_MINER_DIR \
  && tar -xvf $CREEP_MINER_ARCHIVE \
  && cd $CREEP_MINER_PACKAGE \
  && sudo ./install-poco.sh \
  && cmake CMakeLists.txt -DCMAKE_BUILD_TYPE=RELEASE -DNO_GPU=ON -DUSE_AVX2=ON -DCMAKE_INSTALL_PREFIX:PATH=$CREEP_MINER_DIR \
  && make \
  && make install \
  && make clean

# Copy binaries and cleanup
RUN rm -rf $CREEP_MINER_PACKAGE \
  && rm $CREEP_MINER_ARCHIVE

# Uninstall toolchain after installing Poco and building from source
ENV SUDO_FORCE_REMOVE yes
RUN apt-get remove -y \
  build-essential \
  cmake \
  git \
  sudo \
  wget \
  && apt-get autoremove -y \
  && apt-get autoclean \
  && apt-get clean

WORKDIR $CREEP_MINER_DIR

# Add execute permission to binary
RUN chmod +x ./creepMiner

# Expose local web port
EXPOSE 8080

# Copy Shell scripts
COPY miner.sh $CREEP_MINER_DIR
RUN chmod +x ./miner.sh

ENV CREEP_MINER_DATADIR /mnt/miner
ENTRYPOINT ./miner.sh
