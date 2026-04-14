# claude-skills

Custom [Claude Code](https://claude.com/claude-code) skills for personal productivity.

## Skills

| Skill | Description |
|-------|-------------|
| [`/record`](#record--screen-recording) | Screen record your terminal or entire screen using native macOS `screencapture`. Zero dependencies. |
| [`/tax-prep`](#tax-prep--canadian-tax-preparation) | Scan, classify, and organize tax documents for CRA filing. |
| [`/cpush`](#cpush--commit--push) | Commit and push, no PR. |
| [`/shipit`](#shipit--commit-push-and-pr) | Commit, push, and create a PR in one command. |
| [`/sync`](#sync--rebase-on-latest-main) | Pull latest main and rebase the current feature branch. |
| [`/orient`](#orient--clone--branch-status) | Quick status dashboard: clone, branch, port, dev server, changes. |
| [`/spawn`](#spawn--create-a-feature-clone) | Create a new feature clone with branch, port, env, and deps. |
| [`/teardown`](#teardown--remove-a-merged-clone) | Safely remove a feature clone after its branch is merged. |
| [`/dispatch`](#dispatch--triage-ideas-to-lanes) | Triage ideas to workstream lanes and write BRIEF.md assignments. |
| [`/lanes`](#lanes--workstream-dashboard) | Read-only dashboard of all workstream clones — branch, brief, backlog, status. |
| [`/disk-usage`](#disk-usage--disk-space-audit) | Scan home directory for large files and reclaimable caches. Report only, never deletes. |

---

### `/record` — Screen Recording

Record your terminal window or entire screen using the built-in macOS `screencapture` utility. No external dependencies required.

- **Terminal mode** — records only the current terminal window
- **Full screen mode** — records the entire desktop
- Auto-stops after a configurable duration (default 30s)
- Saves as `.mov`, playable natively on macOS

```
/record
```

### `/tax-prep` — Canadian Tax Preparation

Reads all your tax documents from a folder, classifies them against the full CRA taxonomy, cross-references for missing documents, flags audit risks and optimization opportunities, and generates a comprehensive filing plan with a step-by-step checklist.

```
/tax-prep
```

### `/cpush` — Commit & Push

Commit and push without creating a PR. Stages files, generates a conventional commit message from the diff, and pushes to the current feature branch. Use when you want to save progress without opening a PR yet.

```
/cpush
```

### `/shipit` — Commit, Push, and PR

Full commit-push-PR pipeline in one shot. Stages files, generates a conventional commit message from the diff, pushes to the current feature branch, and opens a PR to main (or reports the existing one). Refuses to commit to main, never force-pushes, never skips hooks.

```
/shipit
```

### `/sync` — Rebase on Latest Main

Fetches latest main and rebases the current feature branch on top of it. Reports how many commits behind you are, attempts to resolve conflicts automatically, and aborts cleanly if it can't. Refuses to start if there are uncommitted changes.

```
/sync
```

### `/orient` — Clone & Branch Status

Prints a compact dashboard showing which clone you're in, current branch, configured port, whether the dev server is running, uncommitted changes, and commits ahead of main. Great for re-orienting after switching terminals.

```
/orient
```

### `/spawn` — Create a Feature Clone

Creates a new isolated clone of the current repo for parallel feature development. Clones to `<parent>/<repo>--<name>`, creates a `feat/<name>` branch, copies env files with a unique port, and installs dependencies. Two modes:

- **Direct:** `/spawn auth-refactor` — creates one clone for the named feature
- **Analyze:** `/spawn` with no args — scans the repo structure, suggests logical workstream splits, and lets you pick which to create

```
/spawn auth-refactor
```

### `/teardown` — Remove a Merged Clone

Safely removes a feature clone after verifying its branch was merged into main. Checks for uncommitted work, unpushed commits, and running dev servers before deleting. Requires explicit confirmation; unmerged branches require typing the clone name as double confirmation.

```
/teardown backend
```

### `/dispatch` — Triage Ideas to Lanes

Collect ideas from the user, map each to the right workstream clone based on lane ownership defined in CLAUDE.md, and write assignments. Active ideas get a full `BRIEF.md` in the target clone with files-to-touch and acceptance criteria. If a lane already has an active brief, new ideas queue to `BACKLOG.md`. Cross-lane ideas go to `DISPATCH-NOTES.md` in the main checkout. Always syncs CLAUDE.md to target clones before writing.

```
/dispatch add search, fix auth bug, improve feed
```

### `/lanes` — Workstream Dashboard

Read-only dashboard showing the state of all `<repo>--*` workstream clones. For each clone: current branch, commits ahead of main, active brief status, backlog count, dirty files, and last commit. Flags anomalies like branch mismatches, stale CLAUDE.md, or rebase-in-progress. Works from the main checkout or any clone.

```
/lanes
```

### `/disk-usage` — Disk Space Audit

Scans the home directory for large folders, development artifacts (node_modules, .next, venvs), and reclaimable caches. Produces a structured report with safe-to-clear candidates and the exact commands to run. **Never deletes anything** — report only.

```
/disk-usage
```

---

## Installation

```bash
git clone https://github.com/palpen/claude-skills.git
cd claude-skills
make install
```

That's it. Skills are symlinked into `~/.claude/skills/`, so pulling the latest from the repo automatically updates them.

### Other commands

```bash
make install     # symlink all skills into ~/.claude/skills/
make uninstall   # remove symlinks (doesn't delete the repo)
make list        # show available skills
```

### Update

```bash
cd claude-skills
git pull
```

Symlinks point to the repo, so new content is picked up immediately. If a new skill directory was added, run `make install` again to link it.

### Verify

Run any skill (e.g., `/orient`) in Claude Code. If it shows up in the slash command list, it's installed.

## Adding New Skills

Each skill lives in its own directory with a `SKILL.md` file. See the [Claude Code documentation](https://docs.anthropic.com/en/docs/claude-code) for the skill file format.

## License

MIT
