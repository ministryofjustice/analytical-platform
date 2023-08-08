FROM docker.io/alpine:3.18.3

LABEL org.opencontainers.image.vendor="Ministry of Justice" \
      org.opencontainers.image.authors="Data Platform" \
      org.opencontainers.image.title="Kubectl Image" \
      org.opencontainers.image.description="Kubectl image for Data Platform" \
      org.opencontainers.image.url="https://github.com/ministryofjustice/data-platform/tree/main/containers/kubectl"

ARG KUBECTL_VERSION="v1.27.3"

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
    && chown --recursive ${CONTAINER_USER}:${CONTAINER_GROUP} ${CONTAINER_HOME} \
    && apk add --no-cache --virtual build \
      curl==8.1.2-r0 \
    && curl --location "https://dl.k8s.io/release/${KUBECTL_VERSION}/bin/linux/amd64/kubectl" \
      --output /usr/local/bin/kubectl \
    && chmod +x /usr/local/bin/kubectl \
    && apk del build

USER ${CONTAINER_USER}

WORKDIR ${CONTAINER_HOME}
