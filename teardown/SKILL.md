---
name: teardown
version: 0.1.0
description: |
  Remove a feature clone after its work is merged. Verifies the branch
  was merged into main before deleting. Can target a specific clone or
  list all clones for selection. Use when asked to "teardown", "remove
  clone", "delete workspace", "clean up clone", or "prune workspaces".
allowed-tools:
  - Bash
  - Read
  - Edit
  - Grep
  - Glob
  - AskUserQuestion
---

# Teardown — Remove a Merged Clone

Safely remove a feature clone after its branch has been merged.

## Steps

### 1. Orient — Identify the base repo

Run these in parallel:
- `git rev-parse --show-toplevel` — repo root path
- `basename $(git rev-parse --show-toplevel)` — directory name

Derive the **base repo name** by stripping any `--<suffix>` from the directory name.
Set `BASE_DIR` to the parent directory of the repo root.
Set `CURRENT_DIR` to the repo root.

### 2. Identify the target

**If the user specified a clone name** (e.g., `/teardown backend`):
- Set target to `BASE_DIR/<base-repo-name>--<name>`
- If it doesn't exist, try `BASE_DIR/<base-repo-name>--<name>` with common variations (with/without `feat-` prefix, etc.)
- If still not found, list available clones and ask.

**If no name specified:**
- List all sibling clones: `ls -d BASE_DIR/<base-repo-name>--* 2>/dev/null`
- For each clone, gather in parallel: branch name, merge status, port, uncommitted changes
- Present a numbered list and use `AskUserQuestion` to ask which to tear down (allow multiple selection)

### 3. Pre-flight checks

For each target clone, run these checks:

#### 3a. Refuse to delete base clone

If the target has no `--` suffix (it's the base/main clone), refuse immediately:
"Cannot teardown the base clone. Only feature clones (--<name>) can be removed."

#### 3b. Refuse if user is inside the target

If `CURRENT_DIR` matches the target path, refuse:
"You're inside this clone. Open a different session first, then run /teardown."

#### 3c. Check merge status

Try `gh` first (more reliable):
```bash
cd <target-clone>
BRANCH=$(git branch --show-current)
gh pr list --head "$BRANCH" --state merged --json number,title,url --limit 1
```

If `gh` is not available or returns nothing, fall back to git:
```bash
git fetch origin main
git branch -r --merged origin/main | grep "$BRANCH"
```

Classify as:
- **Merged** — safe to delete
- **Open PR** — warn, show PR URL
- **Unmerged, no PR** — warn strongly

#### 3d. Check for uncommitted work

```bash
cd <target-clone>
git status --porcelain
git log --oneline @{upstream}..HEAD 2>/dev/null  # unpushed commits
```

Report uncommitted changes and unpushed commits if any.

#### 3e. Check dev server

```bash
PORT=$(grep '^PORT=' <target-clone>/.env.local <target-clone>/web/.env.local 2>/dev/null | head -1 | cut -d= -f2)
lsof -ti:$PORT 2>/dev/null
```

### 4. Confirm deletion

Present a clear summary:

```
Teardown: <base-repo-name>--<name>

  Branch:       feat/<name>
  Merge status: Merged (PR #42)
  Uncommitted:  none
  Unpushed:     none
  Dev server:   not running
  Port:         3005

  This will permanently delete <full-path>

  Proceed? (yes/no)
```

Use `AskUserQuestion` to confirm.

**If the branch IS merged:** Require "yes".

**If the branch is NOT merged:** Require the user to type the clone suffix name as confirmation:
"This branch has NOT been merged. Type the clone name '<name>' to confirm deletion:"

### 5. Delete

1. Kill any running dev server: `kill $(lsof -ti:<port>) 2>/dev/null`
2. Optionally delete the remote branch (ask first): `git push origin --delete feat/<name> 2>/dev/null`
3. Delete the clone: `rm -rf <target-clone-path>`

### 6. Update project docs (optional)

Check if any remaining clone's `AGENTS.md` has a port table with a row for the deleted clone.

If found, use `AskUserQuestion`: "Remove the row for --<name> from AGENTS.md? (y/n)"

If yes, edit the table in the appropriate clone.

### 7. Report

```
Torn down: <base-repo-name>--<name>
  Deleted: <full-path>
  Branch:  feat/<name> (remote branch deleted)
  Port <port> is now free.

  Remaining clones:
    --frontend-ui  feat/frontend-ui  port 3001
    --infra        feat/infra        port 3003
```

## Rules

- NEVER delete the base clone (the one without a `--` suffix).
- NEVER delete without explicit confirmation from the user.
- NEVER delete if the user is inside the target clone.
- For unmerged branches, require typing the clone name as confirmation (not just "yes").
- Always check merge status before deleting — this is the primary safety check.
- Offer to delete the remote branch but don't require it.
- If `gh` is not installed, fall back to git-only merge detection.
