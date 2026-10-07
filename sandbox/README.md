# Agent sandbox

Containerised environment for running Claude Code (or any LLM agent) against this repo. The repo is **bind-mounted from the host**, so the agent's edits appear in your working tree immediately — review with your normal local tools, no push/pull round-trip.

## One-time setup

Build the image:

```sh
podman build -t gym-app-sandbox sandbox/
```

Credentials come from your host Claude login: `~/.claude` and `~/.claude.json` are mounted in, so if `claude` works on the host it works in the sandbox. (Alternatively set `CLAUDE_CODE_OAUTH_TOKEN` or `ANTHROPIC_API_KEY` in a gitignored `.env` at the repo root.)

## Running

```sh
./sandbox/run.sh          # shell in the repo
./run_claude.sh           # Claude Code, unattended (--dangerously-skip-permissions)
```

## How it works

- The repo is mounted at its **host path** inside the container, so file paths — and Claude's per-project trust/config, which is keyed by path — match inside and out.
- `--userns=keep-id` maps your host user to the container's `node` user, so files the agent writes are owned by you, not a subuid.
- `backend/.venv` and `frontend/node_modules` are shadowed by container-only named volumes (`gym-app-backend-venv`, `gym-app-frontend-node-modules`): Linux binaries and the host's macOS ones never mix. Run `uv sync` / `npm install` on each side independently.
- Git author/committer identity is passed in via env from the repo's config; the host `~/.gitconfig` is not mounted (it may carry macOS-only credential/signing helpers).

## Properties & trade-offs

- The agent **can write to this repo's working tree on the host** — that is the point. Git is the safety net: review the diff before running anything an agent wrote.
- The rest of the host filesystem is not mounted; rootless podman in a VM, non-root user, `no-new-privileges`, memory/pid limits.
- Push access is opt-in: set `GITHUB_TOKEN` (fine-grained PAT scoped to this repo only) in the gitignored `.env` and the agent can push over HTTPS — the SSH remote is rewritten and the token supplied via env-only git config, so nothing is written to the shared `.git/config`. Without the token, the agent cannot push and publishing is yours to do from the host after review.
- No egress firewall (rootless podman can't easily do iptables): the agent can reach the network. If that matters for untrusted models, add `--network=none` or front it with a proxy.
