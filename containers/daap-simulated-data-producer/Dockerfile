FROM docker.io/alpine:3.18.3

LABEL org.opencontainers.image.vendor="Ministry of Justice" \
      org.opencontainers.image.authors="Data Platform" \
      org.opencontainers.image.title="DaaP Simulated Data Producer" \
      org.opencontainers.image.description="Simulated data producer" \
      org.opencontainers.image.url="https://github.com/ministryofjustice/data-platform/tree/main/containers/daap-simulated-data-producer"

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
    && apk add --no-cache \
      python3==3.11.4-r0 \
      py3-pip==23.1.2-r0 \
      py3-pandas==1.5.3-r1 \
      py3-psycopg2==2.9.6-r1 \
      py3-requests==2.31.0-r0 \
      py3-sqlalchemy==1.4.49-r0

USER ${CONTAINER_USER}

WORKDIR ${CONTAINER_HOME}
