# using ubuntu LTS version
FROM docker.io/ubuntu:jammy AS builder-image

# avoid stuck build due to user prompt
ARG DEBIAN_FRONTEND=noninteractive

COPY ./sources.list /etc/apt/sources.list

RUN set -eux; \
    apt-get update; \
    apt-get install --no-install-recommends -y \
        python3 python3-dev python3-pip build-essential opencc wget libopencc-dev pkg-config; \
	apt-get clean; \
	rm -rf /var/lib/apt/lists/*

COPY ./luoxu/querytrans /build/querytrans
WORKDIR /build/querytrans

ENV RUSTUP_HOME=/usr/local/rustup \
    CARGO_HOME=/usr/local/cargo \
    PATH=/usr/local/cargo/bin:$PATH \
	PKG_CONFIG_PATH==/usr/lib/pkgconfig

RUN set -eux; \
    url="https://sh.rustup.rs"; \
    wget -O rustup-init "$url"; \
    chmod +x rustup-init; \
    ./rustup-init -y --no-modify-path --profile minimal --default-toolchain nightly-x86_64-unknown-linux-gnu; \
    rm rustup-init; \
    export RUSTUP_DIST_SERVER=https://mirrors.tuna.tsinghua.edu.cn/rustup; \
    chmod -R a+w $RUSTUP_HOME $CARGO_HOME; \
    rustup --version; \
    cargo --version; \
    rustc --version; \
	cargo build --release

## build web
FROM docker.io/node:lts as node-builder

COPY ./luoxu-web/ /build/luoxu-web
WORKDIR /build/luoxu-web
RUN set -eux; \
    npm install ; \
    npm run build

## build HttpStdIn
FROM mcr.microsoft.com/dotnet/sdk:8.0 AS dotnet-builder

RUN set -eux; \
    apt-get update; \
    apt-get install --no-install-recommends -y build-essential zlib1g-dev

COPY ./HttpStdIn/ /build/HttpStdIn
WORKDIR /build/HttpStdIn
RUN set -eux; \
    dotnet publish -c Release -r linux-x64

## build runtime image
FROM docker.io/ubuntu:jammy AS runner-image

COPY ./sources.list /etc/apt/sources.list
RUN apt-get update && apt-get install -y python3 pip libpython3-dev opencc &&\
	apt-get clean && rm -rf /var/lib/apt/lists/* &&\
    python3 -m pip install -i https://pypi.tuna.tsinghua.edu.cn/simple --upgrade pip && \
    pip config set global.index-url https://pypi.tuna.tsinghua.edu.cn/simple

COPY --from=builder-image /build/querytrans/target/release/libquerytrans.so /app/querytrans.so
COPY --from=dotnet-builder /build/HttpStdIn/bin/Release/net8.0/linux-x64/publish/HttpStdIn /HttpStdIn
COPY --from=node-builder /build/luoxu-web/dist /wwwroot

COPY ./luoxu/luoxu /app/luoxu
COPY ./luoxu/requirements.txt /app
COPY ./luoxu/ghost.jpg /app
COPY ./luoxu/nobody.jpg /app
COPY ./luoxu/requirements.txt /app

# make sure all messages always reach console
ENV PYTHONUNBUFFERED=1


WORKDIR /app

RUN set -eux; \
    pip install -r requirements.txt; \
    pip install tomli

EXPOSE 9008
EXPOSE 5000

CMD ["/HttpStdIn"]

