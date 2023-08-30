FROM ghcr.io/ministryofjustice/data-platform-daap-python-base:0.3.0

ARG VERSION

ENV VERSION="${VERSION}"

COPY src/var/task ${LAMDA_TASK_ROOT}

CMD ["resync_unprocessed_files.handler"]
