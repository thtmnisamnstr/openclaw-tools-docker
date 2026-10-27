# OpenClaw Tools Docker

An unofficial, browser-enabled OpenClaw gateway based on the official **versioned OpenClaw browser image**, with common Linux dependencies needed for installing skills and plugins through the web UI.

**Included:** Homebrew (Linuxbrew), uv/uvx, Bun, Python/pipx, Go, Rust/Cargo, npm/pnpm (upstream), git, compilers, FFmpeg, ImageMagick, Pandoc, OCR, PDF tools, and network/database utilities. Built for both **linux/amd64** and **linux/arm64**.

## Pull

```sh
docker pull ghcr.io/thtmnisamnstr/openclaw-tools-docker:2026.10.8
# Or the newest successfully published stable image:
docker pull ghcr.io/thtmnisamnstr/openclaw-tools-docker:latest
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
docker build --build-arg OPENCLAW_VERSION=2026.10.8 -t openclaw-tools-docker:2026.10.8 .
```

MIT license for this repository's files; upstream components retain their respective licenses.
