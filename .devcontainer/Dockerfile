FROM mcr.microsoft.com/devcontainers/base:ubuntu-24.04

ARG FLUTTER_VERSION=3.35.2
RUN apt-get update && apt-get install -y --no-install-recommends \
    curl git git-lfs unzip xz-utils zip libglu1-mesa \
    && rm -rf /var/lib/apt/lists/*
RUN git clone --depth 1 --branch ${FLUTTER_VERSION} \
    https://github.com/flutter/flutter.git /opt/flutter \
    && chown -R vscode:vscode /opt/flutter
ENV PATH="/opt/flutter/bin:/opt/flutter/bin/cache/dart-sdk/bin:${PATH}"

USER vscode
RUN flutter config --no-analytics --enable-web \
    && flutter precache --web
USER root
