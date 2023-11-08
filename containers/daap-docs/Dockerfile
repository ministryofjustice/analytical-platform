FROM public.ecr.aws/lambda/nodejs:14

ARG VERSION

ENV VERSION="${VERSION}"

COPY src/var/task ${LAMBDA_TASK_ROOT}

CMD ["main.handler"]
