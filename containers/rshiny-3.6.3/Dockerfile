# hadolint global ignore=DL3008

FROM public.ecr.aws/lts/ubuntu:22.04

LABEL org.opencontainers.image.vendor="Ministry of Justice" \
      org.opencontainers.image.authors="Data Platform" \
      org.opencontainers.image.title="Data Platform R Shiny Image" \
      org.opencontainers.image.description="R Shiny image for Analytical Platform" \
      org.opencontainers.image.url="https://github.com/ministryofjustice/data-platform/tree/main/container-images/rshiny"

ARG R_VERSION="3.6.3" \
    R_ENV_VERSION="0.17.1" \
    AP_SHINY_SERVER_VERSION="0.0.6" \
    SHINY_SERVER_VERSION="1.5.20.1002"

ENV CONTAINER_USER="shiny" \
    CONTAINER_UID="998" \
    CONTAINER_GROUP="shiny" \
    CONTAINER_GID="998" \
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
    && curl --location https://cdn.posit.co/r/ubuntu-2004/pkgs/r-${R_VERSION}_1_amd64.deb \
         --output r.deb \
    && curl --location https://download3.rstudio.org/ubuntu-18.04/x86_64/shiny-server-${SHINY_SERVER_VERSION}-amd64.deb \
         --output shiny-server.deb \
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
    && chown --recursive ${CONTAINER_USER}:${CONTAINER_GROUP} /var/log/shiny-server \
    && chown ${CONTAINER_USER}:${CONTAINER_GROUP} /usr/local/bin/entrypoint.sh \
    && chmod +x /usr/local/bin/entrypoint.sh

WORKDIR ${SHINY_APP}

EXPOSE 9999

ENTRYPOINT [ "/usr/local/bin/entrypoint.sh" ]
