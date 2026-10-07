#!/bin/bash
# Spin up containerised Claude Code in the isolated sandbox (clones from GitHub, no host mounts).
set -euo pipefail

exec "$(dirname "$0")/sandbox/run.sh" claude --dangerously-skip-permissions "$@"
