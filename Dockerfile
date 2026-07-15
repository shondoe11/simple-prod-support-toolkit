FROM ubuntu:22.04

RUN apt-get update && apt-get install -y --no-install-recommends \
    sqlite3 \
    procps \
    sysstat \
    coreutils \
    findutils \
    gzip \
    tar \
    cron \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app
COPY . .
RUN chmod +x scripts/*.sh

CMD ["/bin/bash"]
