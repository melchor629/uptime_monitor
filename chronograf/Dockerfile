ARG ARCH=library

FROM ${ARCH}/debian

ARG CHRONOGRAPH_VERSION=1.6.1

RUN apt-get update && \
    DEBIAN_FRONTEND=noninteractive apt-get install -y curl && \
    case $(uname -m) in \
      armv7l | aarch64 ) \
        export arch=armhf \
        ;; \
      x86_64 ) \
        export arch=amd64 \
        ;; \
      * ) \
        echo "Unsupported architecture $(uname -m)"; \
        exit 1 \
        ;; \
    esac && \
    curl https://dl.influxdata.com/chronograf/releases/chronograf-${CHRONOGRAPH_VERSION}_linux_$arch.tar.gz > chronograf.tar.gz && \
    tar -xvzf chronograf.tar.gz && \
    cd chronograf-* && \
    for file in $(find usr etc var -type f -or -type l); do \
      echo $file -> /$file; \
      mkdir -p /$(dirname $file); \
      mv $file /$file; \
    done && \
    cd / && \
    rm -r /chronograf-* && \
    apt-get purge -y curl && \
    apt-get autoremove -y && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

CMD ["chronograf"]