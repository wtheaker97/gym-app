# Agent sandbox

Isolated environment for running Claude Code (or any LLM agent) against this repo with **no access to the host filesystem**. Nothing is mounted; the container clones the repo from GitHub and the only path back to your machine is `git push` → your review.

## One-time setup

1. **GitHub token**: create a [fine-grained PAT](https://github.com/settings/personal-access-tokens/new) scoped to **only this repository**, with Contents: read & write (add Pull requests: read & write if the agent should open PRs). Do not use your SSH key or a classic PAT.
2. **Claude token**: on the host, run `claude setup-token` and keep the output.
3. Build the image:
   ```sh
   podman build -t gym-app-sandbox sandbox/
   ```

## Running

```sh
export GITHUB_TOKEN=github_pat_...
export CLAUDE_CODE_OAUTH_TOKEN=...   # from claude setup-token

./sandbox/run.sh                      # shell in the cloned repo
./sandbox/run.sh claude --dangerously-skip-permissions   # unattended agent
```

The agent works on a branch and pushes; you review the diff on GitHub and pull. The container is removed on exit (`--rm`) — anything not pushed is gone, by design.

## Properties

- Rootless podman inside a VM: agent → container → non-root user → Linux VM → macOS. No host mounts anywhere.
- Single-repo PAT: worst case is vandalized branches on one repo, recoverable via git. `main` can additionally be protected with a branch-protection rule.
- Git hooks don't survive push/pull, so hook-based payloads can't reach the host. Still review diffs before running anything an agent wrote.
- No egress firewall (rootless podman can't easily do iptables): the agent can reach the network. If that matters for untrusted models, add `--network=none` to run.sh after cloning, or front it with a proxy.
