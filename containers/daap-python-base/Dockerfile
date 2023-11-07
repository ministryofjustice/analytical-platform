FROM public.ecr.aws/lambda/python:3.11

ARG VERSION

ENV BASE_VERSION="${VERSION}"

COPY src/var/task ${LAMBDA_TASK_ROOT}

RUN yum update --assumeyes \
    && yum clean all \
    && rm -rf /var/cache/yum

RUN python -m pip install --no-cache-dir --upgrade pip==23.3.1 \
    && python -m pip install --no-cache-dir --requirement requirements.txt

ONBUILD RUN yum update --assumeyes \
            && yum clean all \
            && rm -rf /var/cache/yum
