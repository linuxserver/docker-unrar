# syntax=docker/dockerfile:1

FROM ghcr.io/linuxserver/baseimage-alpine:3.19 as alpine-buildstage

# set version label
ARG UNRAR_VERSION=7.0.7

RUN \
  echo "**** install build dependencies ****" && \
  apk add --no-cache --virtual=build-dependencies \
    build-base && \
  echo "**** install unrar from source ****" && \
  mkdir /tmp/unrar && \
  curl -o \
    /tmp/unrar.tar.gz -L \
    "https://www.rarlab.com/rar/unrarsrc-${UNRAR_VERSION}.tar.gz" && \
  tar xf \
    /tmp/unrar.tar.gz -C \
    /tmp/unrar --strip-components=1 && \
  cd /tmp/unrar && \
  sed -i 's|LDFLAGS=-pthread|LDFLAGS=-pthread -static|' makefile && \
  make && \
  install -v -m755 unrar /usr/bin && \
  echo "**** cleanup ****" && \
  apk del --purge \
    build-dependencies && \
  rm -rf \
    /root/.cache \
    /tmp/*


FROM ghcr.io/linuxserver/baseimage-ubuntu:jammy as ubuntu-buildstage

# set version label
ARG UNRAR_VERSION=7.0.7

RUN \
  echo "**** install build dependencies ****" && \
  apt-get update && \
  apt-get install -y --no-install-recommends \
    g++ \
    make && \
  echo "**** install unrar from source ****" && \
  mkdir /tmp/unrar && \
  curl -o \
    /tmp/unrar.tar.gz -L \
    "https://www.rarlab.com/rar/unrarsrc-${UNRAR_VERSION}.tar.gz" && \
  tar xf \
    /tmp/unrar.tar.gz -C \
    /tmp/unrar --strip-components=1 && \
  cd /tmp/unrar && \
  sed -i 's|LDFLAGS=-pthread|LDFLAGS=-pthread -static|' makefile && \
  make && \
  install -v -m755 unrar /usr/bin && \
  echo "**** cleanup ****" && \
  apt-get remove -y \
    g++ \
    make && \
  apt-get -y autoremove && \
  apt-get clean && \
  rm -rf \
    /root/.cache \
    /tmp/* \
    /var/lib/apt/lists/* \
    /var/tmp/*


# Storage layer consumed downstream
FROM scratch

# set version label
ARG BUILD_DATE
ARG VERSION
LABEL build_version="Linuxserver.io version:- ${VERSION} Build-date:- ${BUILD_DATE}"
LABEL maintainer="aptalca"

# Add files from buildstage
COPY --from=alpine-buildstage /usr/bin/unrar /usr/bin/unrar-alpine
COPY --from=ubuntu-buildstage /usr/bin/unrar /usr/bin/unrar-ubuntu
