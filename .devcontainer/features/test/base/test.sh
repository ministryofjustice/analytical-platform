#!/usr/bin/env bash

set -e

source dev-container-features-test-lib

check "devcontainer-utils file existence" stat /usr/local/bin/devcontainer-utils
check "moj-codespaces.zsh-theme file existence" stat /home/vscode/.oh-my-zsh/custom/themes/moj-codespaces.zsh-theme
check "first-run-notice.txt file existence" stat /usr/local/etc/vscode-dev-containers/first-run-notice.txt
check ".zshrc file existence" stat /home/vscode/.zshrc

check "direnv version" direnv --version
check "pip3 version" pip3 --version

reportResults
