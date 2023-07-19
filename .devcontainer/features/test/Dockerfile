FROM mcr.microsoft.com/devcontainers/base:ubuntu

COPY .devcontainer/features/src/base/devcontainer-utils /usr/local/bin/devcontainer-utils

RUN mkdir --parents /home/vscode/.dotfiles && chown vscode:vscode /home/vscode/.dotfiles

RUN apt update \
    && apt install --yes \
      python3-pip

RUN pip3 install --upgrade pip
