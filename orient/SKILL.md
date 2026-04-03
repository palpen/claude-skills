---
name: orient
version: 0.1.0
description: |
  Quick orientation check — shows which clone you're in, the current branch,
  dev server port, git status, and whether the dev server is running.
  Use when asked to "orient", "where am I", "which clone", "status",
  or at the start of a new session.
allowed-tools:
  - Bash
  - Read
  - Grep
  - Glob
---

# Orient — Clone & Branch Status

Print a quick status dashboard for the current workspace.

## Steps

Run ALL of these commands in parallel (they are independent), then format the output:

1. `basename $(pwd)` and `pwd` — working directory and clone name
2. `git branch --show-current` — current branch
3. `git status --short` — uncommitted changes (empty = clean)
4. `git log main..HEAD --oneline 2>/dev/null` — unpushed commits vs main
5. `grep '^PORT=' .env.local 2>/dev/null` and `grep '^NEXT_PUBLIC_CLONE_NAME=' .env.local 2>/dev/null` — configured port and clone label (look for `.env.local` in the current directory and in `web/` subdirectory)
6. `lsof -ti:<port> 2>/dev/null` — check if the dev server is running on the configured port (use the PORT from step 5, default 3000)

## Output format

Print a compact dashboard. Example:

```
📍 Orient
─────────────────────────────────
Clone:      job_ai_risk_evaluator--frontend-ui
Branch:     feat/frontend-ui
Port:       3001
Dev server: running ✓  (pid 12345)
Status:     clean
Ahead of main by 3 commits:
  925993f feat: add dev preview page
  aa20113 fix: remove OpenAI branding
  ccf1fce fix: simplify plan page UI
─────────────────────────────────
```

Adapt the output based on what you find:
- If there are uncommitted changes, list them under "Status:" instead of "clean"
- If the dev server is not running, show "not running" and suggest `npm run dev`
- If PORT is not set in .env.local, show "3000 (default)" and note it's not configured
- If on `main`, show a warning: "⚠ You're on main — create a feature branch before making changes"
- If there are no commits ahead of main, say "Up to date with main"

Keep it concise — this is a quick glance, not a deep analysis.
