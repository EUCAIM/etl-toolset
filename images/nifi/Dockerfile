FROM apache/nifi:2.3.0

USER root

# Install required "psql" command
RUN apt-get update \
 && apt-get install -y --no-install-recommends postgresql-client \
 && apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

USER nifi
