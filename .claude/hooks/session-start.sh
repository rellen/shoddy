#!/usr/bin/env bash
set -euo pipefail

# This hook runs only in a remote environment, that is Claude Code on the web.
if [ "${CLAUDE_CODE_REMOTE:-}" != "true" ]; then
  exit 0
fi

# Install mise, if it is not installed already.
#
# Use the official installer. Do not get a GitHub release directly. A web
# session limits GitHub access to the repositories of that session. Thus a
# release asset from github.com gives error 403. The installer at mise.run
# gets mise from mise.jdx.dev. It also examines the checksum, finds the
# operating system and the architecture, and installs mise in
# $HOME/.local/bin/mise.
if ! command -v mise &>/dev/null; then
  curl -fsSL https://mise.run | sh
fi

export PATH="$HOME/.local/bin:$PATH"

# Install Erlang and Elixir. The versions are in the .tool-versions file.
mise install --yes

# Make mise active and keep the paths for the session.
eval "$(mise activate bash)"

# Keep the mise shims and the environment for the Claude session.
if [ -n "${CLAUDE_ENV_FILE:-}" ]; then
  echo "export PATH=\"$HOME/.local/share/mise/shims:$HOME/.local/bin:\$PATH\"" >> "$CLAUDE_ENV_FILE"
  echo 'export ELIXIR_ERL_OPTIONS="+fnu"' >> "$CLAUDE_ENV_FILE"
fi

# Install hex and rebar. The command mix deps.get needs them.
mix local.hex --force --if-missing
mix local.rebar --force --if-missing
