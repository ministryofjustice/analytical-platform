FROM ghcr.io/ministryofjustice/data-platform-daap-python-base:2.0.1

ARG VERSION

ENV VERSION="${VERSION}"

COPY src/var/task ${LAMBDA_TASK_ROOT}

CMD ["resync_unprocessed_files.handler"]
