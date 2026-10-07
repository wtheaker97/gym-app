#!/bin/bash
set -euo pipefail

: "${GITHUB_TOKEN:?Set GITHUB_TOKEN to a fine-grained PAT scoped to the single repo}"
REPO="${REPO:-wtheaker97/gym-app}"
CLONE_DIR="$HOME/workspace/$(basename "$REPO")"

if [ ! -d "$CLONE_DIR/.git" ]; then
  git clone "https://x-access-token:${GITHUB_TOKEN}@github.com/${REPO}.git" "$CLONE_DIR"
fi

git config --global user.name "${GIT_AUTHOR_NAME:-Sandbox Agent}"
git config --global user.email "${GIT_AUTHOR_EMAIL:-sandbox-agent@users.noreply.github.com}"

cd "$CLONE_DIR"
exec "$@"
