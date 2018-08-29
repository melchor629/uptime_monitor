ARG ARCH=library

FROM ${ARCH}/python:3.6-slim

RUN pip install watchgod redis

VOLUME /fing
ENV INFLUXDB_HOST=influxdb
ENV INFLUXDB_PORT=8086
ENV INFLUXDB_DB=activity
ENV REDIS_HOST=redis
ENV REDIS_PORT=6379
ENV REDIS_DB=0

COPY parse.py /

CMD ["python", "/parse.py"]
