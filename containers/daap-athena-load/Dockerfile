FROM public.ecr.aws/lambda/python:3.11

ARG VERSION

ENV VERSION="${VERSION}"

COPY src/var/task ${LAMDA_TASK_ROOT}

RUN python -m pip install --no-cache-dir --upgrade pip==23.1.2 \
    && python -m pip install --no-cache-dir --requirement requirements.txt

CMD ["athena_load_handler.handler"]
