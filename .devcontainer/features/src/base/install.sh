#!/usr/bin/env bash

set -e

cp $( dirname $0 )/devcontainer-utils  /usr/local/bin/devcontainer-utils
cp $( dirname $0 )/moj-codespaces.zsh-theme /home/vscode/.oh-my-zsh/custom/themes/moj-codespaces.zsh-theme
cp $( dirname $0 )/first-run-notice.txt /usr/local/etc/vscode-dev-containers/first-run-notice.txt
cp $( dirname $0 )/.zshrc /home/vscode/.zshrc

chmod +x /usr/local/bin/devcontainer-utils

chown vscode:vscode /usr/local/bin/devcontainer-utils
chown vscode:vscode /home/vscode/.oh-my-zsh/custom/themes/moj-codespaces.zsh-theme
chown vscode:vscode /usr/local/etc/vscode-dev-containers/first-run-notice.txt
chown vscode:vscode /home/vscode/.zshrc

# Persistent Mounts
mkdir --parents /opt/vscode-dev-containers && chown vscode:vscode /opt/vscode-dev-containers
mkdir --parents /home/vscode/workspace && chown vscode:vscode /home/vscode/workspace
mkdir --parents /home/vscode/.commandhistory && chown vscode:vscode /home/vscode/.commandhistory
mkdir --parents /home/vscode/.dotfiles && chown vscode:vscode /home/vscode/.dotfiles
