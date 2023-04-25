FROM ubuntu:focal

ARG r=4.1.3 # must correspond with a rocker tag as per https://hub.docker.com/r/rocker/shiny/tags
ARG shinyserver=0.0.6 # must correspond with an analytics-platform-shiny-server version from here: https://github.com/ministryofjustice/analytics-platform-shiny-server

ENV STRINGI_DISABLE_PKG_CONFIG=true \
  AWS_DEFAULT_REGION=eu-west-1 \
  PATH="/opt/R/${r}/bin:/opt/shiny-server/bin:/opt/shiny-server/ext/node/bin:${PATH}" \
  SHINY_APP=/srv/shiny-server \
  NODE_ENV=production \
  TZ=Etc/UTC \
  LC_ALL=C.UTF-8

RUN  sed -i 's/deb/deb [trusted=yes]/g' /etc/apt/sources.list \
  && sed -i 's,http://security.ubuntu.com/ubuntu/,http://mirror.bytemark.co.uk/ubuntu/,g' /etc/apt/sources.list \
  && sed -i 's,http://archive.ubuntu.com/ubuntu/,http://mirror.bytemark.co.uk/ubuntu/,g' /etc/apt/sources.list \
  && apt-get update -yq -y \
  && apt-get install -yq --no-install-recommends \
    apt-transport-https \
    ca-certificates \
  && sed -i s,http:,https:,g /etc/apt/sources.list \
  && apt-get clean \
  && rm -rf /var/lib/apt/lists/* \
  && echo "dash dash/sh boolean false" | debconf-set-selections \
  && DEBIAN_FRONTEND=noninteractive dpkg-reconfigure dash \
  && apt-get update \
  && DEBIAN_FRONTEND=noninteractive TZ=Etc/UTC apt-get install -yq --no-install-recommends \
    wget \
    curl \
    git \
    gdebi \
    tzdata \
    python3 \
    python3-boto \
    libcurl4-openssl-dev \
    libssl-dev \
    libudunits2-dev \
    libgdal-dev \
    gdal-bin \
    libgeos-dev \
    libproj-dev \
    libsqlite3-dev \
    zlib1g-dev \
    xtail \
  && wget --quiet -O /tmp/r_amd64.deb https://cdn.posit.co/r/ubuntu-2004/pkgs/r-${r}_1_amd64.deb \
  && wget --quiet -O /tmp/shiny-server.deb https://download3.rstudio.org/ubuntu-18.04/x86_64/shiny-server-1.5.20.1002-amd64.deb \
  && wget --quiet -O /tmp/analytics-platform-shiny-server.tar.gz https://github.com/ministryofjustice/analytics-platform-shiny-server/archive/refs/tags/v${shinyserver}.tar.gz \
  && gdebi -n /tmp/r_amd64.deb \
  && sed -i 's;# options(repos = c(CRAN="@CRAN@"));options(repos = c(CRAN = "https://packagemanager.rstudio.com/cran/__linux__/focal/latest"));g' /opt/R/${r}/lib/R/library/base/R/Rprofile \
  && /opt/R/${r}/bin/R -e "install.packages('renv')" \
  && /opt/R/${r}/bin/R -e "install.packages('remotes')" \
  && /opt/R/${r}/bin/R -e "install.packages('shiny')" \
  && gdebi -n /tmp/shiny-server.deb \
  && mkdir -p /var/log/shiny-server \
  && npm i -g /tmp/analytics-platform-shiny-server.tar.gz \
  && chown -R shiny:shiny /srv/shiny-server \
  && rm /tmp/r_amd64.deb /tmp/shiny-server.deb /tmp/analytics-platform-shiny-server.tar.gz \
  && apt-get remove -y \
    gdebi \
  && apt-get autoremove -y \
  && apt-get clean \
  && apt-get autoclean \
  && rm -rf /var/lib/apt/lists/*

WORKDIR /srv/shiny-server

#SHELL ["/bin/bash", "-c"]

# Cleanup shiny-server dir
RUN rm -rf /srv/shiny-server

# Shiny runs as 'shiny' user, adjust app directory permissions
ADD shiny-server.conf /etc/shiny-server/shiny-server.conf
ADD shiny-server.sh /usr/bin/shiny-server.sh
RUN  groupmod -g 998 shiny \
  && usermod -u 998 -u 998 -g 998 shiny \
  && chown -R 998:998 /usr/bin/shiny-server.sh \
  && chmod +x /usr/bin/shiny-server.sh \
  && mkdir -p /srv/shiny/ \
  && chown -R 998:998 /srv/shiny
