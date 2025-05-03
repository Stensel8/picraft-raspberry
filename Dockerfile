# Base image: Debian slim for best perf vs size
FROM debian:bookworm-slim

# non-interactive timezone setup + essentials
ENV DEBIAN_FRONTEND=noninteractive
ENV TZ=UTC

RUN apt-get update \
 && apt-get install -y --no-install-recommends \
    tzdata wget procps ca-certificates \
 && ln -snf /usr/share/zoneinfo/$TZ /etc/localtime \
 && echo $TZ > /etc/timezone \
 && rm -rf /var/lib/apt/lists/*

# Install Azul Zulu 24 (OpenJDK 24)
ARG ZULU_URL=https://cdn.azul.com/zulu/bin/zulu24.30.11-ca-jdk24.0.1-linux_x64.tar.gz
ARG ZULU_ARCHIVE=zulu.tar.gz
ARG ZULU_SHA256=12f6957c3a2a74d36d692cfee3aeeb949f15b5d80dad08bf0d3ed930d66d8659

RUN wget -q -O /tmp/${ZULU_ARCHIVE} ${ZULU_URL} \
 && echo "${ZULU_SHA256}  /tmp/${ZULU_ARCHIVE}" | sha256sum -c - \
 && mkdir -p /opt/zulu24 \
 && tar -xzf /tmp/${ZULU_ARCHIVE} -C /opt/zulu24 --strip-components=1 \
 && ln -s /opt/zulu24/bin/java /usr/local/bin/java \
 && rm /tmp/${ZULU_ARCHIVE}

# Where your world, plugins, configs, logs, etc. live
WORKDIR /mc-data

# Copy in *all* of your mc-data directory from the build context
COPY mc-data/ /mc-data/

# Entrypoint
COPY docker-entrypoint.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/docker-entrypoint.sh

EXPOSE 25565
ENTRYPOINT ["docker-entrypoint.sh"]
CMD []
