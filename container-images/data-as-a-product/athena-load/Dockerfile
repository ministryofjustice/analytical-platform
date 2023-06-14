# lambda base image for Docker from AWS
FROM public.ecr.aws/lambda/python:3.10

WORKDIR /${LAMBDA_TASK_ROOT}

COPY athena_load_handler.py ./
COPY requirements.txt ./

RUN python -m pip install --upgrade pip
RUN python -m pip install -r requirements.txt

CMD ["athena_load_handler.handler"]
