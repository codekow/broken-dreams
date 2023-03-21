
FROM docker.io/tiangolo/uvicorn-gunicorn-fastapi:python3.9

COPY ./app /app

WORKDIR /app

RUN pip install --no-cache -r requirements.txt

ENTRYPOINT [ "python3", "/app/main.py" ]