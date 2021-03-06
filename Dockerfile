FROM debian:jessie-slim
MAINTAINER Erik Rogers <erik.rogers@live.com>

ENV CREEP_MINER_VERSION 2.7.16
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
  deb \
  git \
  sudo \
  wget \
  python-pip \
  && rm -rf /var/lib/apt/lists/*

RUN pip install conan
FROM gcc:6

RUN deb http://ftp.debian.org/debian jessie-backports main \
  && apt-get update && apt-get -t jessie-backports install -y --no-install-recommends \
         cmake \
  && apt-get clean \
  && rm -rf /var/lib/apt/lists/*

# Download and build from source
WORKDIR /tmp
RUN wget $CREEP_MINER_RELEASE \
  && mkdir -p $CREEP_MINER_PACKAGE \
  && mkdir -p $CREEP_MINER_DIR \
  && tar -xvf $CREEP_MINER_ARCHIVE \
  && cd $CREEP_MINER_PACKAGE \
  && conan install . -s compiler.libcxx=libstdc++11 --build=missing
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

# Add the Config
RUN mkdir -p /etc/creeper
ADD mining.conf /etc/creeper

# Copy Shell scripts
COPY miner.sh $CREEP_MINER_DIR
RUN chmod +x ./miner.sh

ENV CREEP_MINER_DATADIR /mnt/miner
ENTRYPOINT ./miner.sh
