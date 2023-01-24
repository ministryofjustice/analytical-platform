FROM mcr.microsoft.com/devcontainers/base:ubuntu

COPY .devcontainer/features/src/devcontainer-utils/devcontainer-utils /usr/local/bin/devcontainer-utils

RUN mkdir --parents /home/vscode/.dotfiles && chown vscode:vscode /home/vscode/.dotfiles
