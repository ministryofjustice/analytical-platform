FROM docker.io/alpine:3.18.3

LABEL org.opencontainers.image.vendor="Ministry of Justice" \
      org.opencontainers.image.authors="Data Platform" \
      org.opencontainers.image.title="Alpine Base Image" \
      org.opencontainers.image.description="Alpine base image for Data Platform" \
      org.opencontainers.image.url="https://github.com/ministryofjustice/data-platform/tree/main/containers/alpine-base"

ENV CONTAINER_GID="10000" \
    CONTAINER_GROUP="nonroot" \
    CONTAINER_UID="10000" \
    CONTAINER_USER="nonroot" \
    CONTAINER_HOME="/app"

RUN addgroup \
      --gid ${CONTAINER_GID} \
      --system \
      ${CONTAINER_GROUP} \
    && adduser \
      --uid ${CONTAINER_UID} \
      --ingroup ${CONTAINER_GROUP} \
      --disabled-password \
      ${CONTAINER_USER} \
    && mkdir --parents ${CONTAINER_HOME} \
    && chown --recursive ${CONTAINER_USER}:${CONTAINER_GROUP} ${CONTAINER_HOME}

USER ${CONTAINER_USER}

WORKDIR ${CONTAINER_HOME}
