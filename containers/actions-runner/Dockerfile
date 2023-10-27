FROM public.ecr.aws/ubuntu/ubuntu:22.04

LABEL org.opencontainers.image.vendor="Ministry of Justice" \
      org.opencontainers.image.authors="Data Platform" \
      org.opencontainers.image.title="Actions Runner" \
      org.opencontainers.image.description="Actions Runner for Data Platform" \
      org.opencontainers.image.url="https://github.com/ministryofjustice/data-platform/tree/main/containers/actions-runner"

ENV CONTAINER_USER="runner" \
    CONTAINER_UID="10000" \
    CONTAINER_GROUP="runner" \
    CONTAINER_GID="10000" \
    CONTAINER_HOME="/actions-runner" \
    DEBIAN_FRONTEND="noninteractive" \
    ACTIONS_RUNNER_VERSION="2.311.0" \
    ACTIONS_RUNNER_PKG_SHA="29fc8cf2dab4c195bb147384e7e2c94cfd4d4022c793b346a6175435265aa278"

SHELL ["/bin/bash", "-o", "pipefail", "-c"]

RUN groupadd \
      --gid ${CONTAINER_GID} \
      --system \
      ${CONTAINER_GROUP} \
    && useradd \
      --uid ${CONTAINER_UID} \
      --gid ${CONTAINER_GROUP} \
      --create-home \
      ${CONTAINER_USER} \
    && mkdir --parents ${CONTAINER_HOME} \
    && chown --recursive ${CONTAINER_USER}:${CONTAINER_GROUP} ${CONTAINER_HOME}

COPY --chown=${CONTAINER_USER}:${CONTAINER_GROUP} src/usr/local/bin/actions-runner-utils /usr/local/bin/actions-runner-utils

RUN apt-get update \
    && apt-get install --yes --no-install-recommends \
      ca-certificates=20230311ubuntu0.22.04.1 \
      curl=7.81.0-1ubuntu1.14 \
      git=1:2.34.1-1ubuntu1.10 \
      jq=1.6-2.1ubuntu3 \
      libicu-dev=70.1-2 \
      lsb-release=11.1.0ubuntu4 \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* \
    && curl --location "https://github.com/actions/runner/releases/download/v${ACTIONS_RUNNER_VERSION}/actions-runner-linux-x64-${ACTIONS_RUNNER_VERSION}.tar.gz" \
      --output "actions-runner-linux-x64-${ACTIONS_RUNNER_VERSION}.tar.gz" \
    && echo "${ACTIONS_RUNNER_PKG_SHA}"  "actions-runner-linux-x64-${ACTIONS_RUNNER_VERSION}.tar.gz" | /usr/bin/sha256sum --check \
    && tar --extract --gzip --file="actions-runner-linux-x64-${ACTIONS_RUNNER_VERSION}.tar.gz" --directory="${CONTAINER_HOME}" \
    && chmod +x /usr/local/bin/actions-runner-utils/*.sh

USER ${CONTAINER_USER}

WORKDIR ${CONTAINER_HOME}

ENTRYPOINT ["/bin/bash", "-c", "/usr/local/bin/actions-runner-utils/entrypoint.sh"]
