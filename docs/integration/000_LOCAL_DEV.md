# Local Dev — Getting Started

**Last updated:** 2026-02-19

## Quick Start (Recommended: Dev Container)

### Prerequisites
- [Docker Desktop](https://www.docker.com/products/docker-desktop) (or Docker Engine + Compose plugin)
- [VS Code](https://code.visualstudio.com/) with the [Dev Containers extension](https://marketplace.visualstudio.com/items?itemName=ms-vscode-remote.remote-containers)

### Steps

```bash
# 1. Clone the integration repo (with submodules)
git clone --recurse-submodules https://github.com/jtarriela/cortex-os.git
cd cortex-os

# 2. Open in VS Code
code .

# 3. When prompted, click "Reopen in Container"
#    (or: Cmd/Ctrl+Shift+P → "Dev Containers: Reopen in Container")
```

The container will:
- Build the dev image (Node 20, Rust stable, Tauri v2 deps)
- Initialize submodules
- Install frontend `node_modules`

### Run the frontend dev server

```bash
# Inside the container terminal:
cd /workspace/frontend
npm run dev
# → Vite dev server at http://localhost:5173
```

### Run full interactive usability session (frontend + Tauri)

```bash
# From repo root:
./scripts/usability-session.sh
```

This script:
- reads the Tauri `devUrl` port from `backend/crates/app/tauri.conf.json`
- starts frontend dev server on that port
- waits for readiness
- launches `cargo tauri dev` from `backend/crates/app`
- stops frontend server automatically when Tauri exits

### Run backend tests (Phase 0.5 spike)

```bash
# Inside the container terminal:
cd /workspace/backend
cargo test
```

---

## Docker Compose (without VS Code)

```bash
# Start the devshell service
docker compose up devshell

# Attach a shell
docker compose exec devshell bash

# Run the standalone frontend service (no IDE)
docker compose --profile dev up frontend
```

---

## Dev Container Image Contents

| Tool | Version | Purpose |
|------|---------|---------|
| Node.js | 20 LTS | Frontend (React/Vite) |
| npm | bundled with Node | Package management |
| Rust | stable | Backend (Tauri/Cargo) |
| Cargo | stable | Rust build & test |
| Tauri CLI | via project dep | App packaging |
| GitHub CLI | latest | Issue/PR management |
| clang/LLVM | system | rusqlite bindgen |
| libwebkit2gtk-4.1 | system | Tauri v2 WebView |
| libsqlcipher-dev | system | SQLCipher build dep |
| xvfb | system | Headless Tauri tests |

---

## Submodule Workflow

```bash
# Update all submodules to their pinned SHAs
git submodule update --init --recursive

# Pull latest from each submodule's main branch
git submodule update --remote --merge

# Refresh frontend dependencies after a submodule SHA update
cd frontend && npm ci && cd ..

# After submodule merges, bump SHA in integration repo
git add backend frontend contracts
git commit -m "chore: bump submodule SHAs post-merge"
```

See `docs/integration/002_RELEASE_PROCESS.md` for the full submodule pinning protocol.

---

## Port Reference

| Port | Service | Notes |
|------|---------|-------|
| 5173 | Vite dev server | Frontend HMR |
| 1420 | Tauri dev window | Phase 1+, not yet active |

---

## Troubleshooting

**Container build fails on `libwebkit2gtk-4.1-dev`:**
Ensure Docker has internet access and the Ubuntu 24.04 universe repo is enabled (the Dockerfile handles this automatically).

**Rust compilation OOM:**
Increase Docker memory limit to ≥ 4 GB in Docker Desktop → Settings → Resources.

**`cargo test` fails in container:**
Run `xvfb-run cargo test` if tests attempt to open a Tauri window (headless display required).
