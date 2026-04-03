---
name: shipit
version: 0.1.0
description: |
  Commit, push, and create a PR in one command. Stages changed files,
  generates a conventional commit message from the diff, pushes to the
  current feature branch, and opens a PR to main. Use when asked to
  "ship it", "commit and push", "commit push and PR", "create a PR",
  or "send it".
allowed-tools:
  - Bash
  - Read
  - Glob
  - Grep
---

# Ship It — Commit, Push, and PR

Run the full commit-push-PR pipeline in one shot. No interactive prompts.

## Steps

1. **Orient** — run `git branch --show-current` and `git status`. If on `main`, stop and warn.

2. **Diff** — run `git diff` and `git diff --cached` to see all changes (staged + unstaged). Also run `git status` to find untracked files. If there are no changes at all, stop and say "Nothing to ship."

3. **Stage** — add all relevant changed and untracked files. Do NOT stage:
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

6. **PR** — check if a PR already exists for this branch (`gh pr view --json state 2>/dev/null`).
   - If no PR exists, create one with `gh pr create`:
     - Title: the commit subject line (or a summary if multiple commits)
     - Body format:
       ```
       ## Summary
       <bullet points summarizing ALL commits on the branch vs main>

       ## Test plan
       <checklist of things to verify>

       🤖 Generated with [Claude Code](https://claude.com/claude-code)
       ```
     - To get the full picture, run `git log main..HEAD --oneline` and `git diff main...HEAD --stat`
   - If a PR already exists and is open, just push (the PR updates automatically). Say "PR already open: <url>".

7. **Report** — print the PR URL (or the existing PR URL) and a one-line summary.

## Rules

- Never commit directly to `main`. If on main, refuse and suggest creating a branch.
- Never force-push.
- Never use `--no-verify`.
- If a pre-commit hook fails, fix the issue, re-stage, and create a NEW commit (do not amend).
- Always confirm the PR URL at the end so the user can click it.
