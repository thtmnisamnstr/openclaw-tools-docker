# OpenClaw Tools Docker

An unofficial, browser-enabled OpenClaw gateway based on the official **versioned OpenClaw browser image**, with common Linux dependencies needed for installing skills and plugins through the web UI.

**Included:** Homebrew (Linuxbrew), uv/uvx, Bun, Python/pipx, Go, Rust/Cargo, npm/pnpm (upstream), git, compilers, FFmpeg, ImageMagick, Pandoc, OCR, PDF tools, and network/database utilities. Built for both **linux/amd64** and **linux/arm64**.

## Pull

```sh
docker pull ghcr.io/thtmnisamnstr/openclaw-tools:2026.10.8
# Or the newest successfully published stable image:
docker pull ghcr.io/thtmnisamnstr/openclaw-tools:latest
```

Version tags match the OpenClaw version inside the container. The latest tag is only published after both native architecture builds and smoke tests succeed.

## Builds and updates

The GitHub Actions workflow on `main` builds the latest stable upstream OpenClaw release on native GitHub Actions runners (`ubuntu-24.04` AMD64 and `ubuntu-24.04-arm` ARM64), smoke-tests the packaged tools and embedded OpenClaw version, then publishes a combined GHCR multi-architecture image under `:<upstream version>` and `:latest`.

After image publication succeeds it creates a GitHub tag and release `v<upstream version>`. You can also trigger the workflow manually. A scheduled check runs daily for new upstream stable releases.

**GitHub package visibility:** A new GHCR container package may be private even though this repository is public. If anonymous `docker pull` is denied, set the package's visibility to **Public** in the GitHub package settings.

The workflow needs GitHub Actions permission to write packages and repository contents, provided via the built-in `GITHUB_TOKEN`.

## Notes

- This image is not an official OpenClaw distribution.
- Some skills are macOS-only or require external APIs, services, or architecture-specific binaries. Installing generic Linux tools does not make every skill compatible.
- Separate sandbox containers do not inherit this image's installed tools.
- Installing third-party skills can execute code. Avoid privileged containers and host Docker-socket mounts.
- Existing models, agents, and credentials must remain in the state volume.

## Build locally

```sh
docker build --build-arg OPENCLAW_VERSION=2026.10.8 -t openclaw-tools:2026.10.8 .
```

MIT license for this repository's files; upstream components retain their respective licenses.

## Tool discovery in OpenClaw exec

The image sets PATH for Homebrew, npm globals, uv/pipx tools and Go binaries.
OpenClaw can rebuild PATH when launching an exec shell, so image ENV alone is
not sufficient. `/usr/local/bin/brew` links to
`/home/linuxbrew/.linuxbrew/bin/brew`, outside the mounted home directories.
Configure the following in each instance's private `openclaw.json` as well:

```json
{
  "tools": {
    "exec": {
      "pathPrepend": [
        "/home/linuxbrew/.linuxbrew/bin",
        "/home/linuxbrew/.linuxbrew/sbin",
        "/home/node/.local/bin",
        "/home/node/.local/share/npm/bin",
        "/home/node/.openclaw/tooling/go/bin"
      ]
    }
  }
}
```

Merge this setting with existing configuration; do not replace the entire file.
For an existing gateway container (replace `YOUR_CONTAINER`):

```sh
docker exec --user node YOUR_CONTAINER node /app/openclaw.mjs config set \
  tools.exec.pathPrepend \
  '["/home/linuxbrew/.linuxbrew/bin","/home/linuxbrew/.linuxbrew/sbin","/home/node/.local/bin","/home/node/.local/share/npm/bin","/home/node/.openclaw/tooling/go/bin"]' --strict-json
```

Restart the container if needed to apply the setting. A restart does not load a
new image; recreate the container after pulling to pick up the symlink change.
Validate through an actual OpenClaw chat exec request, not just `docker exec`:

```sh
command -v brew uv uvx bun go cargo python3 npm pnpm
brew --version
```

See [OpenClaw exec configuration](https://docs.openclaw.ai/tools/bash).
This config targets gateway/sandbox exec; remote node hosts need their own service
PATH. Separate sandbox images must contain the tools themselves.

## Persistent home directories

For installations using bind mounts, keep separate per-instance host directories
for `/home/node` and `/home/linuxbrew`, plus the existing nested state bind at
`/home/node/.openclaw`. Never share these homes between users: they can contain
credentials as well as installed tools. Bind mounts do **not** seed themselves
from image contents. Before first use, seed empty directories from the image,
preserving ownership. Do not mount an empty home over a working installation or
overwrite populated homes during upgrades. Existing homes retain their installed
tool versions when the image changes.

The CI smoke test runs as `node`, checks minimal-PATH brew discovery, exercises a
login shell with the configured prefix, and repeats checks with seeded home bind
mounts and a separate state mount. It tests shell discovery, not a live model or
OpenClaw agent session. To run it locally after building:

```sh
tests/smoke.sh openclaw-tools:2026.10.8 2026.10.8
```

Pull requests build and test both architectures without publishing images.
