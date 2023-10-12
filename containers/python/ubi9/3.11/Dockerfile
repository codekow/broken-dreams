# syntax=docker/dockerfile:1.3-labs
ARG IMAGE_NAME=registry.access.redhat.com/ubi9/ubi:9.2-755
FROM ${IMAGE_NAME}

# cherry picked from below
# https://github.com/devfile/developer-images/blob/main/base/ubi8/Dockerfile

# labels for container catalog
LABEL summary="Python 3.11 devfile base developer image"
LABEL description="Python 3.11 image with base developers tools"
LABEL io.k8s.display-name="python-3.11-devfile-developer-base"
LABEL io.openshift.expose-services=""

USER 0

# install: python
RUN yum install -y python311 python3.11-pip && \
    ln -sf /usr/bin/python3.11 /usr/bin/python && \
    ln -sf /usr/bin/pip3.11 /usr/bin/pip && \
    yum clean all && \
    rm -rf /var/cache/yum/*

USER 1001
