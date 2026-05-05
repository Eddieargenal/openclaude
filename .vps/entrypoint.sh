#!/bin/bash
set -e

# Ensure workspace directory exists
mkdir -p /config/workspace

# code-server reads PASSWORD env var for auth
# user-data and extensions persist via /config volume mount
exec code-server \
  --bind-addr 0.0.0.0:8443 \
  --user-data-dir /config/user-data \
  --extensions-dir /config/extensions \
  --disable-telemetry \
  /config/workspace
