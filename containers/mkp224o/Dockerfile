FROM docker.io/library/alpine:latest AS builder

ARG MKP2240_VERSION=v1.7.0

RUN apk add --no-cache gcc libc-dev libsodium-dev libsodium-static make autoconf git

WORKDIR /build

RUN git clone https://github.com/cathugger/mkp224o.git && \
    cd mkp224o && \
    git checkout $MKP2240_VERSION && \
    ./autogen.sh && \
    ./configure --enable-amd64-51-30k CFLAGS="-O3 -march=x86-64 -mtune=generic -fomit-frame-pointer" LDFLAGS="-static" && \
    make && \
    strip mkp224o && \
    cp mkp224o /usr/local/bin/mkp224o-30k && \
    make clean && \
    ./configure CFLAGS="-O3 -march=x86-64 -mtune=generic -fomit-frame-pointer" LDFLAGS="-static" && \
    make && \
    strip mkp224o && \
    cp mkp224o /usr/local/bin && \
    cd .. && \
    rm -rf mkp244o

FROM scratch
WORKDIR /app
USER 1001

COPY --from=builder /usr/local/bin/ .

ENTRYPOINT ["/app/mkp224o-30k"]
