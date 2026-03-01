#!/usr/bin/env bash
set -euo pipefail

# Only run in remote (Claude Code on the web) environments
if [ "${CLAUDE_CODE_REMOTE:-}" != "true" ]; then
  exit 0
fi

# Install mise if not already installed
if ! command -v mise &>/dev/null; then
  mkdir -p "$HOME/.local/bin"
  MISE_VERSION=$(curl -sI https://github.com/jdx/mise/releases/latest | grep -i location | sed 's/.*tag\/v//' | tr -d '[:space:]')
  curl -fsSL "https://github.com/jdx/mise/releases/download/v${MISE_VERSION}/mise-v${MISE_VERSION}-linux-x64" -o "$HOME/.local/bin/mise"
  chmod +x "$HOME/.local/bin/mise"
fi

export PATH="$HOME/.local/bin:$PATH"

# Install Erlang and Elixir from .tool-versions
mise install --yes

# Activate mise and persist paths for the session
eval "$(mise activate bash)"

# Persist mise shims and environment for the Claude session
if [ -n "${CLAUDE_ENV_FILE:-}" ]; then
  echo "export PATH=\"$HOME/.local/share/mise/shims:$HOME/.local/bin:\$PATH\"" >> "$CLAUDE_ENV_FILE"
  echo 'export ELIXIR_ERL_OPTIONS="+fnu"' >> "$CLAUDE_ENV_FILE"
fi

# Install hex and rebar (needed for mix deps.get)
mix local.hex --force --if-missing
mix local.rebar --force --if-missing
