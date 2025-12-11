FROM postgres:15

COPY ./init-db-scripts /docker-entrypoint-initdb.d

RUN groupadd -g 1000 eucaim && \
    useradd --create-home --shell /bin/bash --uid 1000 --gid 1000 eucaim



