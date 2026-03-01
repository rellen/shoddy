#!/usr/bin/env bash
set -euo pipefail

# Install mise if not already installed
if ! command -v mise &>/dev/null; then
  mkdir -p "$HOME/.local/bin"
  MISE_VERSION=$(curl -sI https://github.com/jdx/mise/releases/latest | grep -i location | sed 's/.*tag\/v//' | tr -d '[:space:]')
  curl -fsSL "https://github.com/jdx/mise/releases/download/v${MISE_VERSION}/mise-v${MISE_VERSION}-linux-x64" -o "$HOME/.local/bin/mise"
  chmod +x "$HOME/.local/bin/mise"
  export PATH="$HOME/.local/bin:$PATH"
fi

# Activate mise in the current shell
eval "$(mise activate bash)"

# Install tools from .tool-versions
mise install --yes
