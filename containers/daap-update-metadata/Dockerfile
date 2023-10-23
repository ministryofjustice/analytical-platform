FROM ghcr.io/ministryofjustice/data-platform-daap-python-base:5.0.0

ARG VERSION

ENV VERSION="${VERSION}"

COPY src/var/task ${LAMDA_TASK_ROOT}

CMD ["update_metadata.handler"]
