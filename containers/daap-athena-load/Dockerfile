FROM ghcr.io/ministryofjustice/data-platform-daap-python-base:0.6.0

ARG VERSION

ENV VERSION="${VERSION}"

COPY src/var/task ${LAMDA_TASK_ROOT}

RUN python -m pip install --no-cache-dir --upgrade pip==23.2.1 \
    && python -m pip install --no-cache-dir --requirement requirements.txt

CMD ["athena_load_handler.handler"]
