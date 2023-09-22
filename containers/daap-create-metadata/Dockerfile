FROM ghcr.io/ministryofjustice/data-platform-daap-python-base:1.0.2

ARG VERSION

ENV VERSION="${VERSION}"

COPY src/var/task ${LAMDA_TASK_ROOT}

CMD ["create_metadata.handler"]
