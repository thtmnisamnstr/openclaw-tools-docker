#!/usr/bin/env bash
set -euo pipefail
image=${1:?Usage: tests/smoke.sh IMAGE EXPECTED_OPENCLAW_VERSION}
version=${2:?Expected OpenClaw version required}
fixture=$(mktemp -d)
seed=
cleanup() {
  if [[ -n "$seed" ]]; then docker rm -f "$seed" >/dev/null; fi
  if [[ $(uname) == Linux ]]; then sudo rm -rf "$fixture"; else rm -rf "$fixture"; fi
}
trap cleanup EXIT

check='set -euo pipefail
  test "$(id -un)" = node
  for tool in node npm pnpm brew uv uvx bun bunx go cargo rustc python3 pipx jq yq ffmpeg pdftotext fd; do
    command -v "$tool" >/dev/null || { echo "Missing $tool" >&2; exit 1; }
  done
  brew --version
  uv --version
  uvx --version
  bun --version
  python3 --version
  go version
  cargo --version
  npm --version
  pnpm --version
  actual="$(node /app/openclaw.mjs --version)"
  echo "OpenClaw version: $actual"
  grep -F "$EXPECTED_OPENCLAW_VERSION" <<< "$actual" >/dev/null
  test -w /home/node/.local
  test -w /home/linuxbrew/.linuxbrew
  # Reproduce the minimal PATH used by a host exec service.
  env PATH=/usr/local/bin:/usr/bin:/bin bash -ec '\''
    test "$(command -v brew)" = /usr/local/bin/brew
    test "$(readlink /usr/local/bin/brew)" = /home/linuxbrew/.linuxbrew/bin/brew
    brew --version
  '\''
  # OpenClaw applies pathPrepend after shell startup. Test that prefix explicitly.
  bash -lc '\''
    export PATH="/home/linuxbrew/.linuxbrew/bin:/home/linuxbrew/.linuxbrew/sbin:/home/node/.local/bin:/home/node/.local/share/npm/bin:/home/node/.openclaw/tooling/go/bin:$PATH"
    brew --version
    command -v uv uvx bun go cargo python3 npm pnpm
  '\''
'
run_check() {
  docker run --rm --user node --entrypoint bash \
    -e "EXPECTED_OPENCLAW_VERSION=$version" "$@" "$image" -ec "$check"
}
run_check

# Bind mounts hide image contents. Seed fresh homes, as an operator must do,
# and retain a separate nested OpenClaw state mount.
seed=$(docker create "$image")
mkdir -p "$fixture/node" "$fixture/linuxbrew" "$fixture/state"
docker cp "$seed:/home/node/." "$fixture/node/"
docker cp "$seed:/home/linuxbrew/." "$fixture/linuxbrew/"
# CI hosts need the same writable UID/GID as the image's node user.
uid=$(docker run --rm --entrypoint id "$image" -u node)
gid=$(docker run --rm --entrypoint id "$image" -g node)
if [[ $(uname) == Linux ]]; then sudo chown -R "$uid:$gid" "$fixture"; fi
run_check \
  --mount "type=bind,src=$fixture/node,dst=/home/node" \
  --mount "type=bind,src=$fixture/linuxbrew,dst=/home/linuxbrew" \
  --mount "type=bind,src=$fixture/state,dst=/home/node/.openclaw"
