#!/usr/bin/env bash
set -euo pipefail

# Only run in remote (Claude Code on the web) environments
if [ "${CLAUDE_CODE_REMOTE:-}" != "true" ]; then
  exit 0
fi

# Install mise if not already installed.
#
# Use the official installer rather than fetching a GitHub release directly:
# web sessions scope GitHub access to the session's own repositories, so
# github.com release assets return 403. mise.run downloads from mise.jdx.dev,
# verifies the checksum, detects os/arch, and installs to $HOME/.local/bin/mise.
if ! command -v mise &>/dev/null; then
  curl -fsSL https://mise.run | sh
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
