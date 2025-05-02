# Base image: slim Debian for best perf vs size
FROM debian:bookworm-slim

# Install essentials + tzdata (noninteractive so build won’t hang)
RUN apt-get update \
 && DEBIAN_FRONTEND=noninteractive apt-get install -y \
      wget procps ca-certificates tzdata \
 && rm -rf /var/lib/apt/lists/*

# Install Azul Zulu 24 (OpenJDK 24)
ARG ZULU_URL_ARCHIVE=https://cdn.azul.com/zulu/bin/zulu24.30.11-ca-jdk24.0.1-linux_x64.tar.gz
ARG ZULU_ARCHIVE_NAME=zulu.tar.gz
ARG ZULU_SHA256=12f6957c3a2a74d36d692cfee3aeeb949f15b5d80dad08bf0d3ed930d66d8659
RUN wget -q -O /tmp/${ZULU_ARCHIVE_NAME} ${ZULU_URL_ARCHIVE} \
 && echo "${ZULU_SHA256}  /tmp/${ZULU_ARCHIVE_NAME}" | sha256sum -c - \
 && mkdir -p /opt/zulu24 \
 && tar -xzf /tmp/${ZULU_ARCHIVE_NAME} -C /opt/zulu24 --strip-components=1 \
 && ln -s /opt/zulu24/bin/java /usr/local/bin/java \
 && rm /tmp/${ZULU_ARCHIVE_NAME}

# Working directory for server data
WORKDIR /mc-data

# Copy entrypoint script
COPY docker-entrypoint.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/docker-entrypoint.sh

# Expose Minecraft port & data volume
EXPOSE 25565
VOLUME ["/mc-data"]

# Entrypoint: downloads jar, verifies, allocates RAM, then exec Java
ENTRYPOINT ["docker-entrypoint.sh"]
CMD []
