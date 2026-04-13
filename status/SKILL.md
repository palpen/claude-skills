---
name: status
version: 0.1.0
description: |
  Check progress across all workstream clones. Shows branch, dirty files,
  last commit, active brief, and backlog for each lane. Works from the
  main checkout or any clone. Use when asked to "status", "check progress",
  "what's happening", "show workstreams", or "lane status".
allowed-tools:
  - Bash
  - Read
  - Glob
  - Grep
---

# Status — Workstream Dashboard

Read-only dashboard showing the state of all workstream clones.

## Steps

### 1. Orient

Run in parallel:
- `basename $(git rev-parse --show-toplevel)` — current directory name
- `git rev-parse --show-toplevel` — repo root

Derive the **base repo name** by stripping any `--<suffix>` from the directory name.
Set `BASE_DIR` to the parent of the repo root.
Set `MAIN_DIR` to `BASE_DIR/<base-repo-name>`.

This skill works from the main checkout OR any clone. If running from a clone, note it but proceed normally.

### 2. Discover clones

List all sibling clones:
```bash
ls -d BASE_DIR/<base-repo-name>--* 2>/dev/null
```

Extract the lane name from each suffix. If no clones exist, report "No workstream clones found" and stop.

### 3. Gather data

For each clone, run ALL of these in parallel (each clone can be a separate parallel Bash call):

```bash
echo "=== <lane> ==="
git -C <clone-path> branch --show-current 2>/dev/null || echo "NO BRANCH"
git -C <clone-path> status --porcelain 2>/dev/null
git -C <clone-path> log --oneline -1 2>/dev/null || echo "NO COMMITS"
git -C <clone-path> log main..HEAD --oneline 2>/dev/null | wc -l | tr -d ' '
```

Also read (reads are not sandboxed):
- `<clone-path>/BRIEF.md` — extract the first `# Brief:` line and the `Status` checkbox
- `<clone-path>/BACKLOG.md` — count `###` headers (each = one queued item)

For the main checkout:
```bash
git -C <MAIN_DIR> status --porcelain 2>/dev/null
git -C <MAIN_DIR> log --oneline -1 2>/dev/null
test -f <MAIN_DIR>/DISPATCH-NOTES.md && echo "has_notes" || echo "no_notes"
```

If DISPATCH-NOTES.md exists, extract cross-lane item titles (lines matching `## Cross-lane:`).

### 4. Detect anomalies

For each clone, check and flag:
- **Branch mismatch:** current branch doesn't match `feat/<lane>` — show "expected feat/<lane>, found <actual>"
- **Rebase in progress:** `git -C <path> status` contains "rebase in progress" — flag prominently
- **CLAUDE.md out of sync:** compare line count of clone's CLAUDE.md vs main's. If different, flag "CLAUDE.md out of sync — run /dispatch to resync"
- **Clone missing:** directory doesn't exist — show "NOT FOUND — run /spawn <lane>"

### 5. Format output

Print a compact dashboard. Target: fits in one terminal screen.

```
Status — <base-repo-name> workstreams
═══════════════════════════════════════════════════════
<repo>--<lane>      feat/<lane>        <N> ahead
  Brief:   "<title>"  [x] Complete | [ ] Not started | [ ] In progress
  Backlog: <N> queued
  Dirty:   <N> files (<file1>, <file2>, ...)
  Last:    <hash> <message>
─────────────────────────────────────────────────────────
<repo>--<lane>      feat/<lane>        clean
  Brief:   none
  Backlog: 0 queued
  Last:    <hash> <message>
─────────────────────────────────────────────────────────
Cross-lane (DISPATCH-NOTES.md): <count> pending
  - "<title>" — <lanes involved>

Main (<repo>/)      main               clean
  Last:    <hash> <message>
═══════════════════════════════════════════════════════
```

Adapt based on what you find:
- "Dirty" shows up to 4 filenames; beyond that show count only
- "commits ahead" = count from `git log main..HEAD`. If 0, show "clean"
- If BRIEF.md doesn't exist, show "Brief: none"
- Backlog count = number of `###` headers in BACKLOG.md (0 if no file)
- Cross-lane section only appears if DISPATCH-NOTES.md exists with items
- Main checkout is always the last row — it's context, not the focus
- Anomaly flags appear inline with the affected clone (e.g., "⚠ Branch mismatch")

### Extended mode

If the user invokes `/status full` or `/status --brief`:
- Print the full BRIEF.md contents for each clone that has one, indented under the lane section
- Print full BACKLOG.md contents if they exist

## Rules

- **Strictly read-only.** Never modify any file, branch, or config.
- All reads are cross-directory — reads are not sandboxed, no bypass needed.
- Works from the main checkout or any clone.
- Do not fetch or pull — show local state only.
- Do not attempt network operations.
- Keep output compact — one screen or less for the default view.
- Lane discovery is dynamic — scan for `<repo>--*` directories, don't hardcode names.
