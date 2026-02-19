# Cortex OS — Dev Container Image
# Provides: Node 20, Rust stable, Tauri v2 system deps, SQLite/SQLCipher build deps,
#           GitHub CLI, Clang/LLVM (for rusqlite bindgen), xvfb (for headless Tauri tests)

FROM ubuntu:24.04

ARG DEBIAN_FRONTEND=noninteractive
ARG USERNAME=dev
ARG USER_UID=1000
ARG USER_GID=1000

# ─── System packages ────────────────────────────────────────────────────────

RUN apt-get update && apt-get install -y --no-install-recommends \
    # Core build tools
    build-essential \
    cmake \
    curl \
    wget \
    file \
    git \
    pkg-config \
    unzip \
    ca-certificates \
    gnupg \
    lsb-release \
    sudo \
    # Tauri v2 system dependencies (Linux)
    libwebkit2gtk-4.1-dev \
    libssl-dev \
    libxdo-dev \
    libayatana-appindicator3-dev \
    librsvg2-dev \
    # Virtual display for headless Tauri build/test
    xvfb \
    # SQLite / SQLCipher build dependencies
    libsqlite3-dev \
    libsqlcipher-dev \
    tcl \
    # Clang + LLVM for rusqlite bindgen
    clang \
    libclang-dev \
    llvm \
    # Utilities
    jq \
    tree \
    && rm -rf /var/lib/apt/lists/*

# ─── Node.js 20 LTS (via NodeSource) ────────────────────────────────────────

RUN curl -fsSL https://deb.nodesource.com/setup_20.x | bash - \
    && apt-get install -y nodejs \
    && rm -rf /var/lib/apt/lists/*

# ─── GitHub CLI ─────────────────────────────────────────────────────────────

RUN curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg \
        | dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg \
    && chmod go+r /usr/share/keyrings/githubcli-archive-keyring.gpg \
    && echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] \
        https://cli.github.com/packages stable main" \
        | tee /etc/apt/sources.list.d/github-cli.list > /dev/null \
    && apt-get update && apt-get install -y gh \
    && rm -rf /var/lib/apt/lists/*

# ─── Non-root dev user ───────────────────────────────────────────────────────

RUN groupadd --gid $USER_GID $USERNAME \
    && useradd --uid $USER_UID --gid $USER_GID -m -s /bin/bash $USERNAME \
    && echo "$USERNAME ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

USER $USERNAME

# ─── Rust (stable) via rustup ────────────────────────────────────────────────

RUN curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs \
        | sh -s -- -y --default-toolchain stable --profile default
ENV PATH="/home/${USERNAME}/.cargo/bin:${PATH}"

# Add wasm32 target (for Tauri frontend bundling if needed later)
RUN rustup target add wasm32-unknown-unknown

# ─── Workspace ───────────────────────────────────────────────────────────────

WORKDIR /workspace
