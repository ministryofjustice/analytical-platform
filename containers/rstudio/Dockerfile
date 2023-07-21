ARG NOTEBOOK_BASE=docker.io/jupyter/r-notebook:ubuntu-22.04
FROM $NOTEBOOK_BASE

ARG RSTUDIO_URL=https://rstudio.org/download/latest/stable/server/focal/rstudio-server-latest-amd64.deb
ARG LIBSSL_URL=http://archive.ubuntu.com/ubuntu/pool/main/o/openssl/libssl1.1_1.1.1f-1ubuntu2.19_amd64.deb

USER root
WORKDIR /root

RUN wget -O rstudio.deb "$RSTUDIO_URL"     \
      && wget -O libssl.deb "$LIBSSL_URL"  \
      && chown _apt rstudio.deb libssl.deb

RUN apt update && apt -y dist-upgrade      \
      && apt install -y /root/libssl.deb   \
      && apt install -y /root/rstudio.deb  \
      && rstudio-server stop               \
      && apt clean                         \
      && rm -rf                            \
            /var/lib/apt/lists/*           \
            /run/rstudio-server            \
            /root/libssl.deb               \
            /root/rstudio.deb

RUN pip install                            \
      jupyter-server-proxy                 \
      jupyter-rsession-proxy

ENV PATH="$PATH:/usr/sbin/rstudio-server"

# NB_USER is inherited from notebooks base image
USER ${NB_USER}
WORKDIR $HOME
