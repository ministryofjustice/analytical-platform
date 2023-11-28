FROM ghcr.io/ministryofjustice/data-platform-daap-python-base:7.0.0
# change to 7.5.0 once released

ARG VERSION

ENV VERSION="${VERSION}"

COPY src/var/task ${LAMBDA_TASK_ROOT}

CMD ["delete_table.handler"]
