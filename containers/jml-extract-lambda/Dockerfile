FROM public.ecr.aws/lambda/python:3.12

ARG VERSION

ENV BASE_VERSION="${VERSION}"

COPY src/var/task ${LAMDA_TASK_ROOT}

RUN python -m pip install --no-cache-dir --upgrade pip==23.3.2 \
    && python -m pip install --no-cache-dir --requirement requirements.txt

CMD ["handler.handler"]
