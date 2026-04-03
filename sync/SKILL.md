---
name: sync
version: 0.1.0
description: |
  Pull latest main and rebase the current feature branch on top of it.
  Handles conflicts gracefully. Use when asked to "sync", "rebase on main",
  "pull latest", "update branch", or "catch up with main".
allowed-tools:
  - Bash
  - Read
  - Edit
  - Grep
  - Glob
---

# Sync — Rebase on Latest Main

Pull the latest `main` branch and rebase the current feature branch on top of it.

## Steps

1. **Preflight checks:**
   - Run `git branch --show-current` — if on `main`, stop and warn ("You're on main, nothing to sync.")
   - Run `git status --porcelain` — if there are uncommitted changes, stop and say: "You have uncommitted changes. Commit or stash them first, then run /sync again."

2. **Fetch** — run `git fetch origin main` to get the latest without modifying anything.

3. **Check divergence** — run `git log HEAD..origin/main --oneline` to see how many commits behind you are.
   - If already up to date (no output), say "Already up to date with main." and stop.
   - Otherwise, report how many commits behind: "Branch is N commits behind main. Rebasing..."

4. **Rebase** — run `git pull --rebase origin main`.

5. **Handle conflicts:**
   - If the rebase succeeds cleanly, report success: "Rebased on latest main (N new commits). You're up to date."
   - If there are conflicts:
     - Run `git diff --name-only --diff-filter=U` to list conflicted files
     - Report the conflicted files to the user
     - Attempt to resolve each conflict by reading the file, understanding both sides, and making the correct edit
     - After resolving each file, run `git add <file>`
     - When all conflicts are resolved, run `git rebase --continue`
     - If a conflict is ambiguous and you can't confidently resolve it, run `git rebase --abort`, report the conflicted files, and ask the user to resolve manually

6. **Verify** — run `git log --oneline -5` and report the current state.

## Rules

- Never force-push after a rebase unless the user explicitly asks.
- Never rebase `main` itself.
- If the working tree is dirty, refuse to start — don't stash automatically (the user may have staged changes intentionally).
- After a successful rebase, remind the user: "You'll need to force-push (`git push --force-with-lease`) to update the remote branch."
