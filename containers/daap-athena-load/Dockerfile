FROM 374269020027.dkr.ecr.eu-west-2.amazonaws.com/data-platform-python-base-ecr-repo:0.1.0

ARG VERSION

ENV VERSION="${VERSION}"

COPY src/var/task ${LAMDA_TASK_ROOT}

RUN python -m pip install --no-cache-dir --upgrade pip==23.2.1 \
    && python -m pip install --no-cache-dir --requirement requirements.txt

CMD ["athena_load_handler.handler"]
