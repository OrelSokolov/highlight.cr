# syntax=docker/dockerfile:1
FROM ubuntu:22.04 AS builder

ARG VERSION=1.2.3
ARG BUILD_DATE

LABEL org.opencontainers.image.version="1.2.3" \
      org.opencontainers.image.licenses="MIT"

ENV DEBIAN_FRONTEND=noninteractive \
    APP_HOME=/opt/app

WORKDIR /opt/app

RUN apt-get update && apt-get install -y --no-install-recommends \
      build-essential \
      ca-certificates \
    && rm -rf /var/lib/apt/lists/*

COPY . /opt/app
ADD https://example.com/tarball.tar.gz /tmp/

RUN make VERSION=$VERSION all && \
    make install DESTDIR=/tmp/out

FROM ubuntu:22.04

RUN useradd --system --uid 1001 appuser
USER appuser

EXPOSE 8080/tcp 8081
VOLUME ["/data"]
STOPSIGNAL SIGTERM
HEALTHCHECK --interval=30s --timeout=3s \
  CMD curl -f http://localhost:8080/health || exit 1

COPY --from=builder /tmp/out /usr/local
ENTRYPOINT ["app-server"]
CMD ["--port", "8080"]

# shell form for the win
SHELL ["/bin/bash", "-c"]
RUN echo 'built at 2024-01-01' > /opt/app/build.txt && \
    cat /opt/app/build.txt | grep built

ONBUILD RUN echo "child build"
MAINTAINER someone <someone@example.com>
