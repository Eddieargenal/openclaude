#!/bin/bash
set -e

# Ensure workspace directory exists
mkdir -p /config/workspace

# Make oc() available in non-login shells (code-server terminal)
grep -q 'profile.d/openclaude.sh' /root/.bashrc 2>/dev/null || \
  echo '. /etc/profile.d/openclaude.sh' >> /root/.bashrc

# code-server reads PASSWORD env var for auth
# user-data and extensions persist via /config volume mount
exec code-server \
  --bind-addr 0.0.0.0:8443 \
  --user-data-dir /config/user-data \
  --extensions-dir /config/extensions \
  --disable-telemetry \
  /config/workspace
