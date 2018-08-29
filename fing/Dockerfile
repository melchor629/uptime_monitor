ARG ARCH=library

FROM ${ARCH}/debian:stretch-slim

ARG FING_URL=https://39qiv73eht2y1az3q51pykkf-wpengine.netdna-ssl.com/wp-content/uploads/2018/02/FingKit_CLI_Linux_Others.zip

RUN apt-get update && \
    DEBIAN_FRONTEND=noninteractive apt-get install -y curl unzip && \
    mkdir /fing && \
    cd /fing && \
    curl -SL ${FING_URL} > fingkit.zip && \
    unzip fingkit.zip && \
    case $(uname -m) in \
      armv7l ) \
        export arch=armhf \
        ;; \
      aarch64 ) \
        export arch=arm64 \
        ;; \
      x86_64 ) \
        export arch=amd64 \
        ;; \
      * ) \
        echo "Unsupported architecture $(uname -m)"; \
        exit 1 \
        ;; \
    esac && \
    tar -xvzf Linux_Others/fing-*-$arch.tar.gz && \
    cd fing-*-$arch && \
    for file in $(find usr -type f -or -type l); do \
      echo $file -> /$file; \
      mkdir -p /$(dirname $file); \
      mv $file /$file; \
    done && \
    cd / && \
    rm -r /fing && \
    apt-get purge -y curl && \
    apt-get autoremove -y && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

CMD ["fing"]
