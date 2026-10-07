#!/bin/bash
# Spin up containerised Claude Code in the sandbox (repo bind-mounted from the host).
set -euo pipefail

exec "$(dirname "$0")/sandbox/run.sh" claude --dangerously-skip-permissions "$@"
