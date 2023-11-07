FROM public.ecr.aws/lambda/python:3.10

ARG VERSION

ENV BASE_VERSION="${VERSION}"

COPY src/var/task ${LAMDA_TASK_ROOT}

RUN yum update --assumeyes \
    && yum clean all \
    && rm --recursive --force /var/cache/yum

RUN python -m pip install --no-cache-dir --upgrade pip==23.2.1 \
    && python -m pip install --no-cache-dir --requirement requirements.txt

CMD ["push_to_catalogue.handler"]
