# syntax=docker/dockerfile:1
ARG OPENCLAW_VERSION=2026.10.8
FROM ghcr.io/astral-sh/uv:latest AS uv
FROM oven/bun:1 AS bun
FROM ghcr.io/openclaw/openclaw:${OPENCLAW_VERSION}-browser

ARG OPENCLAW_VERSION
LABEL org.opencontainers.image.title="OpenClaw Tools Docker" \
      org.opencontainers.image.description="OpenClaw browser image with Linux skill and plugin dependencies" \
      org.opencontainers.image.source="https://github.com/thtmnisamnstr/openclaw-tools-docker" \
      org.opencontainers.image.version="${OPENCLAW_VERSION}" \
      org.opencontainers.image.licenses="MIT"

USER root
SHELL ["/bin/bash", "-o", "pipefail", "-c"]

RUN apt-get update && \
    DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
      bash ca-certificates curl wget git git-lfs gnupg \
      build-essential pkg-config cmake ninja-build make \
      autoconf automake libtool \
      file procps lsof less nano \
      jq yq ripgrep fd-find fzf \
      tar unzip zip gzip bzip2 xz-utils zstd \
      openssl openssh-client rsync \
      dnsutils iproute2 iputils-ping netcat-openbsd \
      python3 python3-dev python3-pip python3-venv python-is-python3 pipx \
      golang-go rustc cargo ruby \
      libssl-dev libffi-dev libsqlite3-dev libpq-dev \
      zlib1g-dev libbz2-dev liblzma-dev libreadline-dev \
      libxml2-dev libxslt1-dev libjpeg-dev libpng-dev \
      sqlite3 postgresql-client \
      ffmpeg imagemagick ghostscript poppler-utils qpdf \
      tesseract-ocr sox libimage-exiftool-perl pandoc \
      fonts-dejavu-core fonts-liberation && \
    rm -rf /var/lib/apt/lists/*

COPY --from=uv /uv /uvx /usr/local/bin/
COPY --from=bun /usr/local/bin/bun /usr/local/bin/bun
RUN ln -s /usr/local/bin/bun /usr/local/bin/bunx && \
    ln -s /usr/bin/fdfind /usr/local/bin/fd

RUN install -d -o node -g node -m 0755 /home/linuxbrew && \
    install -d -o node -g node -m 0755 /home/linuxbrew/.linuxbrew && \
    install -d -o node -g node -m 0755 /home/node/.local && \
    install -d -o node -g node -m 0755 /home/node/.local/bin && \
    install -d -o node -g node -m 0755 /home/node/.local/share/npm

ENV HOME=/home/node \
    HOMEBREW_NO_ANALYTICS=1 \
    HOMEBREW_NO_SUDO=1 \
    NPM_CONFIG_PREFIX=/home/node/.local/share/npm \
    PIPX_HOME=/home/node/.local/share/pipx \
    PIPX_BIN_DIR=/home/node/.local/bin \
    UV_TOOL_BIN_DIR=/home/node/.local/bin \
    GOPATH=/home/node/.openclaw/tooling/go \
    BUN_INSTALL_BIN=/home/node/.local/bin
ENV PATH="/usr/local/bin:/home/node/.local/bin:/home/node/.local/share/npm/bin:/home/node/.openclaw/tooling/go/bin:/home/linuxbrew/.linuxbrew/bin:/home/linuxbrew/.linuxbrew/sbin:${PATH}"

USER node
RUN NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)" && \
    brew --version && uv --version && uvx --version && bun --version && \
    python3 --version && go version && cargo --version && \
    npm --version && pnpm --version

# OpenClaw exec may reconstruct a minimal PATH without image ENV entries.
# Link directly to the real script: a link to bin/brew adds a second symlink
# hop that Homebrew does not resolve correctly. Keep it outside mounted homes.
USER root
RUN ln -s /home/linuxbrew/.linuxbrew/Homebrew/bin/brew /usr/local/bin/brew
USER node

# Preserve official ENTRYPOINT, CMD, HEALTHCHECK and installed Chromium.
