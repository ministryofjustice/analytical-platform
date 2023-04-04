# hadolint global ignore=DL3008

FROM public.ecr.aws/lts/ubuntu@sha256:5f6d7e4dad348dbbae3c1e960dcaba98c2e262902c67c9bc41d5f2417cebaeb8

LABEL org.opencontainers.image.vendor="Ministry of Justice" \
      org.opencontainers.image.authors="Data Platform Core Infrastructure" \
      org.opencontainers.image.title="Data Platform R Shiny Image" \
      org.opencontainers.image.description="R Shiny image for Analytical Platform" \
      org.opencontainers.image.url="https://github.com/ministryofjustice/data-platform/tree/main/container-images/rshiny"

ARG R_VERSION="4.1.3" \
    R_ENV_VERSION="0.17.1" \
    AP_SHINY_SERVER_VERSION="0.0.6"

ENV CONTAINER_USER="nonroot" \
    CONTAINER_UID="10000" \
    CONTAINER_GROUP="nonroot" \
    CONTAINER_GID="10000" \
    DEBIAN_FRONTEND="noninteractive" \
    NODE_ENV="production" \
    SHINY_APP="/srv/shiny-server"

COPY src/etc/shiny-server/shiny-server.conf /etc/shiny-server/shiny-server.conf
COPY src/usr/local/bin/entrypoint.sh /usr/local/bin/entrypoint.sh

RUN groupadd --gid ${CONTAINER_GID} ${CONTAINER_GROUP} \
    && useradd --uid ${CONTAINER_UID} --gid ${CONTAINER_GROUP} --shell /bin/bash --create-home ${CONTAINER_USER} \
    && apt-get update \
    && apt-get upgrade --assume-yes \
    && apt-get install --assume-yes --no-install-recommends \
        ca-certificates \
        curl \
        git \
        nodejs \
        npm \
        python3 \
        python3-pip \
        python3-boto3 \
        python3-venv \
    && curl --location https://github.com/ministryofjustice/analytics-platform-shiny-server/archive/refs/tags/v${AP_SHINY_SERVER_VERSION}.tar.gz \
         --output analytics-platform-shiny-server.tar.gz \
    && curl --location https://cdn.posit.co/r/ubuntu-2204/pkgs/r-${R_VERSION}_1_amd64.deb \
         --output r.deb \
    && npm install --global ./analytics-platform-shiny-server.tar.gz \
    && apt-get install --assume-yes ./r.deb \
    && apt-get install --assume-yes ./shiny-server.deb \
    && rm --force \
        analytics-platform-shiny-server.tar.gz \
        r.deb \
        shiny-server.deb \
    && apt-get clean \
    && rm --recursive --force /var/lib/apt/lists/* \
    && R -e "install.packages(c('remotes', 'shiny'))" \
    && R -e "remotes::install_github('rstudio/renv@${R_ENV_VERSION}')" \
    && mkdir --parents ${SHINY_APP} \
    && mkdir --parents /var/log/shiny-server \
    && chown --recursive ${CONTAINER_USER}:${CONTAINER_GROUP} ${SHINY_APP} \
    && chown --recursive ${CONTAINER_USER}:${CONTAINER_GROUP} /var/log/shiny-server

USER ${CONTAINER_USER}

WORKDIR ${SHINY_APP}

EXPOSE 9999

ENTRYPOINT [ "/usr/local/bin/entrypoint.sh" ]
