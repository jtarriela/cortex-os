#!/usr/bin/env bash
# Post-create setup — runs once after the devcontainer is created.
# Installs frontend dependencies and configures git submodules.

set -euo pipefail

echo "==> Initializing git submodules..."
git submodule update --init --recursive

echo "==> Installing frontend dependencies..."
cd /workspace/frontend && npm install

echo "==> Verifying Rust toolchain..."
rustc --version
cargo --version

echo "==> Cortex OS dev environment ready."
echo "    Run 'npm run dev' inside /workspace/frontend to start the Vite server."
echo "    Run 'cargo test' inside /workspace/backend to run backend tests."
