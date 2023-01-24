FROM mcr.microsoft.com/devcontainers/base:ubuntu

ARG MOJ_DATA_PLATFORM_AWS_IAM_EMAIL

COPY usr/local/bin/devcontainer/shared-library /usr/local/bin/devcontainer/shared-library
COPY usr/local/bin/ministryofjustice/ /usr/local/bin/ministryofjustice/
COPY usr/local/etc/vscode-dev-containers/first-run-notice.txt /usr/local/etc/vscode-dev-containers/first-run-notice.txt
COPY home/vscode/.oh-my-zsh/custom/themes/moj-codespaces.zsh-theme /home/vscode/.oh-my-zsh/custom/themes/moj-codespaces.zsh-theme
COPY home/vscode/.zshrc /home/vscode/.zshrc
COPY home/vscode/.aws/config /home/vscode/.aws/config
COPY home/vscode/.kube/config /home/vscode/.kube/config

USER root

RUN sed -i "s|http://ports.ubuntu.com/ubuntu-ports/|https://mirrors.ocf.berkeley.edu/ubuntu-ports/|g" /etc/apt/sources.list
RUN sed -i "s|MOJ_DATA_PLATFORM_AWS_IAM_EMAIL|${MOJ_DATA_PLATFORM_AWS_IAM_EMAIL}|g" /home/vscode/.aws/config

RUN chown --recursive vscode:vscode /usr/local/bin/devcontainer
RUN chown --recursive vscode:vscode /usr/local/bin/ministryofjustice && chmod --recursive 755 /usr/local/bin/ministryofjustice
RUN chown vscode:vscode /home/vscode/.oh-my-zsh/custom/themes/moj-codespaces.zsh-theme
RUN chown vscode:vscode /home/vscode/.zshrc
RUN chown vscode:vscode /home/vscode/.aws/config
RUN chown vscode:vscode /home/vscode/.kube/config && chmod 600 /home/vscode/.kube/config

RUN mkdir --parents /home/vscode/workspace && chown vscode:vscode /home/vscode/workspace
RUN mkdir --parents /home/vscode/.commandhistory && chown vscode:vscode /home/vscode/.commandhistory
RUN mkdir --parents /home/vscode/.dotfiles && chown vscode:vscode /home/vscode/.dotfiles
RUN mkdir --parents /home/vscode/.awsvault && chown vscode:vscode /home/vscode/.awsvault

USER vscode

VOLUME [ "/home/vscode/workspace" ]
VOLUME [ "/home/vscode/.commandhistory" ]
VOLUME [ "/home/vscode/.awsvault" ]
