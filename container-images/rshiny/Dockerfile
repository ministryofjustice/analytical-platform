# hadolint global ignore=DL3008

FROM public.ecr.aws/lts/ubuntu@sha256:5f6d7e4dad348dbbae3c1e960dcaba98c2e262902c67c9bc41d5f2417cebaeb8

LABEL org.opencontainers.image.vendor="Ministry of Justice" \
      org.opencontainers.image.authors="Data Platform Core Infrastructure" \
      org.opencontainers.image.title="Data Platform R Shiny Image" \
      org.opencontainers.image.description="R Shiny image for Analytical Platform" \
      org.opencontainers.image.url="https://github.com/ministryofjustice/data-platform/tree/main/container-images/ubuntu/rshiny"

ARG R_VERSION="4.1.3" \
    AP_SHINY_SERVER_VERSION="0.0.6" \
    SHINY_SERVER_VERSION="1.5.20.1002"

ENV DEBIAN_FRONTEND="noninteractive"

RUN apt-get update \
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
    && curl --location https://github.com/ministryofjustice/analytics-platform-shiny-server/archive/refs/tags/v${AP_SHINY_SERVER_VERSION}.tar.gz \
         --output analytics-platform-shiny-server.tar.gz \
    && curl --location https://cdn.posit.co/r/ubuntu-2204/pkgs/r-${R_VERSION}_1_amd64.deb \
         --output r.deb \
    && curl --location https://download3.rstudio.org/ubuntu-18.04/x86_64/shiny-server-${SHINY_SERVER_VERSION}-amd64.deb \
         --output shiny-server.deb \
    && npm install --global ./analytics-platform-shiny-server.tar.gz \
    && apt-get install --assume-yes ./r.deb \
    && apt-get install --assume-yes ./shiny-server.deb
