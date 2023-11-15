# FROM public.ecr.aws/lambda/nodejs:14
FROM public.ecr.aws/lambda/nodejs:14.2023.11.13.09

ARG VERSION

ENV VERSION="${VERSION}"

COPY src/var/task ${LAMBDA_TASK_ROOT}

CMD ["main.handler"]
