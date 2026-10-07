#!/bin/bash
# Launch the agent sandbox (rootless podman, repo bind-mounted from the host).
# Usage: ./run.sh              -> interactive shell in the repo
#        ./run.sh claude       -> Claude Code (add --dangerously-skip-permissions to let it run unattended)
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"

ENV_FILE="$REPO_ROOT/.env"
if [ -f "$ENV_FILE" ]; then
  set -a
  source "$ENV_FILE"
  set +a
fi

# Git identity for commits made inside the container (the host ~/.gitconfig
# isn't mounted — it may carry macOS-only helpers like osxkeychain/gpg).
GIT_NAME="$(git -C "$REPO_ROOT" config user.name || true)"
GIT_EMAIL="$(git -C "$REPO_ROOT" config user.email || true)"

ARGS=(
  --rm -it
  --security-opt=no-new-privileges
  --pids-limit=512
  --memory=4g
  # Map the host user to the container's node user (uid 1000) so files
  # written on the mount come out owned by you.
  --userns=keep-id:uid=1000,gid=1000
  # Repo mounted at its host path so paths (and Claude's per-project
  # trust/config, keyed by path) match inside and out.
  -v "$REPO_ROOT:$REPO_ROOT"
  -w "$REPO_ROOT"
  # Linux deps must not clobber the host's macOS ones: shadow the
  # dependency dirs with container-only named volumes.
  -v "gym-app-backend-venv:$REPO_ROOT/backend/.venv"
  -v "gym-app-frontend-node-modules:$REPO_ROOT/frontend/node_modules"
  -e GIT_AUTHOR_NAME="$GIT_NAME"
  -e GIT_AUTHOR_EMAIL="$GIT_EMAIL"
  -e GIT_COMMITTER_NAME="$GIT_NAME"
  -e GIT_COMMITTER_EMAIL="$GIT_EMAIL"
  -e CLAUDE_CODE_OAUTH_TOKEN
  -e ANTHROPIC_API_KEY
)

# Optional push access: a fine-grained single-repo PAT in .env. Git config is
# injected via env only — .git/config is shared with the host, so the remote
# URL and credential helper must never be written to it from in here.
if [ -n "${GITHUB_TOKEN:-}" ]; then
  ARGS+=(
    -e GITHUB_TOKEN
    -e GIT_CONFIG_COUNT=2
    -e GIT_CONFIG_KEY_0=url.https://github.com/.insteadOf
    -e GIT_CONFIG_VALUE_0=git@github.com:
    -e GIT_CONFIG_KEY_1=credential.https://github.com.helper
    -e GIT_CONFIG_VALUE_1='!f() { echo username=x-access-token; echo "password=${GITHUB_TOKEN}"; }; f'
  )
fi

# Share the host's Claude login/session state.
[ -d "$HOME/.claude" ] && ARGS+=(-v "$HOME/.claude:/home/node/.claude")
[ -f "$HOME/.claude.json" ] && ARGS+=(-v "$HOME/.claude.json:/home/node/.claude.json")

exec podman run "${ARGS[@]}" localhost/gym-app-sandbox "$@"
