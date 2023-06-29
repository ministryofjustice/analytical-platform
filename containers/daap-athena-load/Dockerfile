FROM public.ecr.aws/lambda/python:3.10

COPY src/var/task .

RUN python -m pip install --upgrade pip \
    && python -m pip install --requirement requirements.txt

CMD ["athena_load_handler.handler"]
