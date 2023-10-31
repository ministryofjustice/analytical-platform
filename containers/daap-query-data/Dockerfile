FROM ghcr.io/ministryofjustice/data-platform-daap-python-base:5.3.1

ARG VERSION

ENV VERSION="${VERSION}"

COPY src/var/task ${LAMDA_TASK_ROOT}

RUN python -m pip install --no-cache-dir --upgrade pip==23.2.1 \
    && python -m pip install --no-cache-dir --requirement requirements.txt

CMD ["query_data.handler"]
