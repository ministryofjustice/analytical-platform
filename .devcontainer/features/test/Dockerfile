# hadolint global ignore=DL3008,DL3013,DL4006

FROM mcr.microsoft.com/devcontainers/base:ubuntu

ENV NODE_MAJOR=18

COPY .devcontainer/features/src/base/devcontainer-utils /usr/local/bin/devcontainer-utils

RUN mkdir --parents /home/vscode/.dotfiles && chown vscode:vscode /home/vscode/.dotfiles

RUN apt-get install --yes \
      ca-certificates \
      curl \
      gnupg \
    && mkdir --parents /etc/apt/keyrings \
    && curl -fsSL https://deb.nodesource.com/gpgkey/nodesource-repo.gpg.key | gpg --dearmor -o /etc/apt/keyrings/nodesource.gpg \
    && echo "deb [signed-by=/etc/apt/keyrings/nodesource.gpg] https://deb.nodesource.com/node_$NODE_MAJOR.x nodistro main" | tee /etc/apt/sources.list.d/nodesource.list

RUN apt-get update \
    && apt-get install --yes \
      python3-pip \
      nodejs

RUN pip3 install --no-cache-dir --upgrade pip
