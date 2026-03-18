#!/bin/sh
set -e

# Railway (and most orchestrators) mount volumes as root.
# This entrypoint ensures the data directories exist with correct
# ownership before dropping to the unprivileged runtime user.

ZEROCLAW_UID=65534
ZEROCLAW_GID=65534
DATA_DIR=/zeroclaw-data
CONFIG_DIR="$DATA_DIR/.zeroclaw"
WORKSPACE_DIR="$DATA_DIR/workspace"

mkdir -p "$CONFIG_DIR" "$WORKSPACE_DIR"

# Always sync config from repo if it exists, otherwise use minimal default for first run
if [ -f "/app/config.toml" ]; then
  echo "Syncing config.toml from /app to $CONFIG_DIR..."
  cp "/app/config.toml" "$CONFIG_DIR/config.toml"
elif [ ! -f "$CONFIG_DIR/config.toml" ]; then
  echo "No pre-existing config.toml, creating minimal default..."
  cat > "$CONFIG_DIR/config.toml" <<CONF
workspace_dir = "$WORKSPACE_DIR"
config_path = "$CONFIG_DIR/config.toml"
default_provider = "anthropic"
default_model = "claude-sonnet-4-20250514"
default_temperature = 0.7

[gateway]
host = "0.0.0.0"
allow_public_bind = true
CONF
fi

chown -R "$ZEROCLAW_UID:$ZEROCLAW_GID" "$DATA_DIR"

exec gosu "$ZEROCLAW_UID:$ZEROCLAW_GID" "$@"
