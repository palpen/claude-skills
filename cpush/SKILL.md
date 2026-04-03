---
name: cpush
version: 0.1.0
description: |
  Commit and push without creating a PR. Stages changed files, generates a
  conventional commit message from the diff, and pushes to the current branch.
  Use when asked to "commit and push", "save and push", "cpush", or "push my changes".
allowed-tools:
  - Bash
  - Read
  - Glob
  - Grep
---

# Commit & Push

Stage, commit, and push — no PR.

## Steps

1. **Orient** — run `git branch --show-current` and `git status`. If on `main`, stop and warn.

2. **Diff** — run `git diff` and `git diff --cached` to see all changes (staged + unstaged). Also run `git status` to find untracked files. Run `git log --oneline -5` to match the repo's commit message style. If there are no changes at all, stop and say "Nothing to commit."

3. **Stage** — add all relevant changed and untracked files by name. Do NOT stage:
   - `.env*` files
   - Files that look like they contain secrets (credentials, tokens, keys)
   - `node_modules/`, `.next/`, `dist/`, `build/`
   If you skip any files, mention which ones and why.

4. **Commit** — generate a conventional commit message from the staged diff:
   - Use the format: `type: short description` (feat, fix, test, chore, docs, refactor)
   - Keep the subject line under 72 characters
   - Add a body paragraph if the change is non-trivial (more than ~20 lines changed or multiple concerns)
   - End with: `Co-Authored-By: Claude <noreply@anthropic.com>`
   - Use a HEREDOC to pass the message to `git commit -m`

5. **Push** — run `git push -u origin <branch>`. If the push fails due to SSH/auth, retry once with sandbox disabled.

6. **Report** — print the branch name, commit hash, and a one-line summary.

## Rules

- Never commit directly to `main`. If on main, refuse and suggest creating a branch.
- Never force-push.
- Never use `--no-verify`.
- If a pre-commit hook fails, fix the issue, re-stage, and create a NEW commit (do not amend).
