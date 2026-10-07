#!/bin/bash
# Launch the isolated agent sandbox (rootless podman, no host mounts).
# Usage: ./run.sh              -> interactive shell in the cloned repo
#        ./run.sh claude       -> Claude Code (add --dangerously-skip-permissions to let it run unattended)
set -euo pipefail

: "${GITHUB_TOKEN:?Export GITHUB_TOKEN (fine-grained PAT, single-repo scope) first}"

exec podman run --rm -it \
  --security-opt=no-new-privileges \
  --pids-limit=512 \
  --memory=4g \
  -e GITHUB_TOKEN \
  -e CLAUDE_CODE_OAUTH_TOKEN \
  -e ANTHROPIC_API_KEY \
  -e REPO \
  localhost/gym-app-sandbox "$@"
