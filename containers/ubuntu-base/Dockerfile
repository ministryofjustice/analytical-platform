FROM docker.io/ubuntu:22.04

LABEL org.opencontainers.image.vendor="Ministry of Justice" \
      org.opencontainers.image.authors="Data Platform" \
      org.opencontainers.image.title="Ubuntu Base Image" \
      org.opencontainers.image.description="Ubuntu base image for Data Platform" \
      org.opencontainers.image.url="https://github.com/ministryofjustice/data-platform/tree/main/containers/ubuntu-base"

ENV CONTAINER_USER="nonroot" \
    CONTAINER_UID="10000" \
    CONTAINER_GROUP="nonroot" \
    CONTAINER_GID="10000" \
    CONTAINER_HOME="/app" \
    DEBIAN_FRONTEND="noninteractive"

RUN groupadd \
      --gid ${CONTAINER_GID} \
      --system \
      ${CONTAINER_GROUP} \
    && useradd \
      --uid ${CONTAINER_UID} \
      --gid ${CONTAINER_GROUP} \
      ${CONTAINER_USER} \
    && mkdir --parents ${CONTAINER_HOME} \
    && chown --recursive ${CONTAINER_USER}:${CONTAINER_GROUP} ${CONTAINER_HOME}

USER ${CONTAINER_USER}

WORKDIR ${CONTAINER_HOME}
