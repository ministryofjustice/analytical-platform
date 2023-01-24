FROM mcr.microsoft.com/devcontainers/base:ubuntu

COPY usr/local/bin/devcontainer/shared-library /usr/local/bin/devcontainer/shared-library
COPY usr/local/bin/ministryofjustice/ /usr/local/bin/ministryofjustice/
COPY usr/local/etc/vscode-dev-containers/first-run-notice.txt /usr/local/etc/vscode-dev-containers/first-run-notice.txt
COPY home/vscode/.oh-my-zsh/custom/themes/moj-codespaces.zsh-theme /home/vscode/.oh-my-zsh/custom/themes/moj-codespaces.zsh-theme
COPY home/vscode/.zshrc /home/vscode/.zshrc

USER root

RUN chown --recursive vscode:vscode /usr/local/bin/devcontainer
RUN chown --recursive vscode:vscode /usr/local/bin/ministryofjustice && chmod --recursive 755 /usr/local/bin/ministryofjustice
RUN chown vscode:vscode /home/vscode/.oh-my-zsh/custom/themes/moj-codespaces.zsh-theme
RUN chown vscode:vscode /home/vscode/.zshrc

RUN mkdir --parents /home/vscode/workspace && chown vscode:vscode /home/vscode/workspace
RUN mkdir --parents /home/vscode/.commandhistory && chown vscode:vscode /home/vscode/.commandhistory
RUN mkdir --parents /home/vscode/.dotfiles && chown vscode:vscode /home/vscode/.dotfiles

USER vscode
