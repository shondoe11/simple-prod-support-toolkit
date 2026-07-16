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
    python3 \
    python3-pip \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app
COPY . .
RUN chmod +x scripts/*.sh scripts/*.py
RUN pip3 install --no-cache-dir -r api/requirements.txt

CMD ["/bin/bash"]
