FROM ubuntu:22.04

RUN apt-get update -y \
    && apt-get install -y xattr \
    && rm -rf /var/lib/apt/lists/*

RUN mkdir -p /data/creator/

WORKDIR /data/creator
