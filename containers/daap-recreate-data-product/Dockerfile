FROM public.ecr.aws/lambda/python:3.11

ARG VERSION

ENV VERSION="${VERSION}"

COPY src/var/task ${LAMDA_TASK_ROOT}

CMD ["recreate_data_product.handler"]
