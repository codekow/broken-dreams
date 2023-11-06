FROM docker.io/library/ubuntu:20.04

ARG MKP2240_VERSION=v1.6.1

RUN apt-get update && \
    apt-get install --no-install-recommends -y \
      ca-certificates git \
      gcc libc6-dev libsodium-dev make autoconf && \
    apt-get clean all

RUN git clone https://github.com/cathugger/mkp224o.git && \
    cd mkp224o && \
    git checkout $MKP224O_REVISION && \
    ./autogen.sh && \
    ./configure --enable-amd64-51-30k && \
    make && \
    cp mkp224o /usr/local/bin/mkp224o-30k && \
    make clean && \
    ./configure && \
    make && \
    cp mkp224o /usr/local/bin && \
    cd .. && \
    rm -rf mkp244o

USER 1001

WORKDIR /tmp

#ENTRYPOINT /usr/local/bin/mkp224o -y
