FROM public.ecr.aws/lts/ubuntu@sha256:5f6b39af2870c0357181b0625ee9f524af2085965151b63435e17971fcb4f136

LABEL org.opencontainers.image.vendor="Ministry of Justice" \
      org.opencontainers.image.authors="Data Platform Core Infrastructure" \
      org.opencontainers.image.title="Data Platform Base Image" \
      org.opencontainers.image.description="Container base image for Data Platform" \
      org.opencontainers.image.url="https://github.com/ministryofjustice/data-platform/tree/main/container-images/ubuntu/base"

ENV CONTAINER_USER="nonroot" \
    CONTAINER_UID="10000" \
    CONTAINER_GROUP="nonroot" \
    CONTAINER_GID="10000" \
    CONTAINER_HOME="/app" \
    DEBIAN_FRONTEND="noninteractive"

RUN groupadd --gid ${CONTAINER_GID} ${CONTAINER_GROUP} \
    && useradd --uid ${CONTAINER_UID} --gid ${CONTAINER_GROUP} --shell /bin/bash --create-home ${CONTAINER_USER} \
    && mkdir --parents ${CONTAINER_HOME} \
    && chown --recursive ${CONTAINER_USER}:${CONTAINER_GROUP} ${CONTAINER_HOME} \
    && apt-get update \
    && apt-get upgrade --assume-yes \
    && rm -rf /var/lib/apt/lists/*

USER ${CONTAINER_USER}

WORKDIR ${CONTAINER_HOME}
