FROM python:2.7-alpine

ENV MODEL_TYPE=type
ENV MODEL_NAME=name
ENV MODEL_VERSION=version

ENV PYTHON_START=/app/python/server.py

ADD consul.json /app/
ADD start.sh /app/
COPY python/ /app/python/

EXPOSE 8080

RUN apk add --update curl \
        && rm -rf /var/cache/apk/* /tmp/*
CMD ["app/start.sh"]
