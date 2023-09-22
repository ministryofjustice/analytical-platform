FROM ghcr.io/ministryofjustice/data-platform-daap-python-base:2.0.0

ARG VERSION

ENV VERSION="${VERSION}"

COPY src/var/task ${LAMDA_TASK_ROOT}

CMD ["reload_data_product.handler"]
