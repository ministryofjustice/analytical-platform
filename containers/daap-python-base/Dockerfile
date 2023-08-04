FROM public.ecr.aws/lambda/python:3.11

ARG VERSION

ENV BASE_VERSION="${VERSION}"

COPY src/var/task .

RUN python -m pip install --no-cache-dir --upgrade pip==23.2.1 \
    && python -m pip install --no-cache-dir --requirement requirements.txt
