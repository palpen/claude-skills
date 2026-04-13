---
name: dispatch
version: 0.1.0
description: |
  Triage ideas and features to the right workstream lanes, stage feature
  branches, and write BRIEF.md assignments to each clone. Run from the
  main checkout when you have one or more ideas to distribute across
  parallel workstreams. Use when asked to "dispatch", "triage ideas",
  "stage work", "queue features", or "assign tasks to lanes".
allowed-tools:
  - Bash
  - Read
  - Write
  - Edit
  - Glob
  - Grep
  - AskUserQuestion
---

# Dispatch — Triage Ideas to Workstream Lanes

Collect ideas from the user, map each to the right workstream clone, and stage assignments.

## Steps

### 1. Orient — Identify the repo and validate context

Run in parallel:
- `git rev-parse --show-toplevel` — repo root
- `basename $(git rev-parse --show-toplevel)` — directory name
- `git remote get-url origin 2>/dev/null` — remote URL

Derive the **base repo name** by stripping any `--<suffix>` from the directory name.
Set `BASE_DIR` to the parent of the repo root.
Set `MAIN_DIR` to `BASE_DIR/<base-repo-name>` (the main checkout without a `--` suffix).

**Refuse if running from a clone:** If the current directory name contains `--`, stop immediately:
"Run /dispatch from the main checkout (<base-repo-name>/), not from a clone."

### 2. Discover lanes

Lanes can come from two sources. Try them in order:

#### 2a. Check CLAUDE.md for lane definitions

Read `CLAUDE.md` at the repo root. Search for a section named "Parallel Workstream Lanes", "Workstream Lanes", or "Workstream Boundaries" (case-insensitive).

If found, parse the lane entries. Each lane is identified by:
- A checkout name pattern: `<repo>--<lane-name>`
- A branch name: `feat/<lane-name>`
- A description of what the lane owns (pages, components, actions, files, DB tables, etc.)

Store the parsed lanes as a list of `{ name, description, owned_files }`.

#### 2b. Scan for existing clones

List `BASE_DIR/<base-repo-name>--*` directories. For each, extract the lane name from the suffix.

If CLAUDE.md had lane definitions, cross-reference: warn about clones that exist but aren't in CLAUDE.md, and lanes defined but with no matching clone.

If CLAUDE.md had NO lane definitions, build a lane list from the discovered clones. For each clone, read its CLAUDE.md or scan its recent git log to infer what it covers. Present the inferred lanes to the user for confirmation.

#### 2c. No lanes found

If no CLAUDE.md section and no `--*` clones exist, stop:
"No workstream lanes found. Run /spawn to create clones first, or add a 'Parallel Workstream Lanes' section to CLAUDE.md."

### 3. Collect ideas

If the user provided ideas inline (e.g., `/dispatch add search, fix auth bug, improve feed`), parse the text as a comma-separated or newline-separated list.

If invoked with no args, use `AskUserQuestion`:
```
What ideas or features do you want to dispatch?
List them one per line or comma-separated.
```

### 4. Triage

For each idea, evaluate which lane it belongs to based on the lane descriptions and owned files from Step 2.

Classify each idea as:
- **Single lane** — clearly belongs to one lane based on the files/domains it would touch
- **Cross-lane** — spans multiple lanes (e.g., requires changes in both auth and feed)
- **Unroutable** — doesn't fit any defined lane

Produce a triage table:
```
Idea                              Lane          Notes
────────────────────────────────────────────────────────
Add restaurant search             supply        post-form + places API
Fix avatar upload bug             platform      profile + storage
Improve feed sort order           demand        reservation-feed
Add SMS receipts                  cross-lane    platform (Twilio) + supply (trigger)
```

### 5. Confirm triage

Use `AskUserQuestion` to present the triage and ask for corrections:
```
Triage result — does this look right?

[table from Step 4]

Cross-lane ideas:
  "Add SMS receipts"
    <lane-1>: <what this lane does>
    <lane-2>: <what this lane does>
    Suggest: dispatch <lane> piece first

Type corrections (e.g., "idea 2 → demand"), or "ok" to proceed:
```

If the user corrects anything, re-triage the affected items and re-present. Loop until confirmed.

### 6. Preflight check

For each lane that will receive a dispatch, run in parallel:
```bash
git -C <clone-path> branch --show-current
git -C <clone-path> status --porcelain
test -f <clone-path>/BRIEF.md && cat <clone-path>/BRIEF.md | head -5 || echo "no_brief"
test -f <clone-path>/BACKLOG.md && echo "has_backlog" || echo "no_backlog"
```

Evaluate and flag:
- **Clone doesn't exist** — skip this lane, report "run /spawn <lane> first". Hold the idea in DISPATCH-NOTES.md.
- **Existing BRIEF.md not marked complete** — new idea goes to BACKLOG.md, not BRIEF.md. Tell the user.
- **Clone on unexpected branch** — warn but don't block.
- **Clone has dirty files** — note in output, don't block.

### 7. Sync CLAUDE.md

Copy the main checkout's CLAUDE.md to each target clone. Batch into one command:
```bash
cp <MAIN_DIR>/CLAUDE.md <clone-1>/CLAUDE.md && \
cp <MAIN_DIR>/CLAUDE.md <clone-2>/CLAUDE.md
```

Also copy AGENTS.md if it exists and is referenced from CLAUDE.md.

Only sync to lanes receiving a dispatch in this run.

**Note:** This write targets sibling directories outside the current project. It will trigger a sandbox override prompt — batch all copies into one command to minimize prompts.

### 8. Write assignments

For each lane receiving work:

#### Active assignment → BRIEF.md

Write only if no existing BRIEF.md, or existing one has `[x]` in its Status section.

```markdown
# Brief: <idea title>

**Lane:** <lane> | **Branch:** feat/<lane> | **Dispatched:** <YYYY-MM-DD>

## Task
<2-5 sentence expanded description. Include enough context for a Claude Code
session to start immediately without asking questions. Reference specific files,
components, or patterns from the lane's ownership list in CLAUDE.md.>

## Files to touch
- <file paths inferred from lane ownership and the nature of the idea>

## Acceptance criteria
- [ ] <specific, testable criterion>
- [ ] <specific, testable criterion>
- [ ] No cross-lane files modified without flagging

## Status
[ ] Not started
```

#### Queued work → BACKLOG.md

If a lane already has an active BRIEF.md, append to BACKLOG.md:

```markdown
# Backlog: <repo>--<lane>

When the current BRIEF.md is complete, promote the next item.

## Queue
### 1. <idea title>
**Dispatched:** <YYYY-MM-DD>

<brief description>
```

If BACKLOG.md already exists, append with the next sequence number.

#### Cross-lane ideas → DISPATCH-NOTES.md

Write to `DISPATCH-NOTES.md` in the **main checkout** (no sandbox issue):

```markdown
# Dispatch Notes

## Cross-lane: <idea title>
**Dispatched:** <YYYY-MM-DD>

- **<lane-1>:** <what this lane does for this idea>
- **<lane-2>:** <what this lane does for this idea>
- **Dependency:** <which side ships first and why>
- **Shared surface:** <files both lanes need to agree on>
```

**Note:** All writes to clone directories use Bash to handle the sandbox boundary. Batch writes per clone into single commands where possible.

### 9. Report

Print a summary:
```
Dispatch complete
─────────────────────────────────────────────────────────
<lane>     BRIEF.md    "<idea title>"
             CLAUDE.md synced

<lane>     BACKLOG.md  "<idea title>"  (queued #1)
             Active brief: "<existing brief title>"

Cross-lane   DISPATCH-NOTES.md  "<idea title>"

Next steps:
  cd <clone-path> and open a new Claude Code session
  Run /lanes to monitor progress
─────────────────────────────────────────────────────────
```

## Rules

- Never run from a `--<lane>` clone. Only from the main checkout.
- Always sync CLAUDE.md before writing BRIEF.md.
- Never overwrite an active (non-complete) BRIEF.md — queue to BACKLOG.md instead.
- Always confirm triage with the user before writing anything.
- Expand every idea into a full brief with files-to-touch and acceptance criteria. Never write a one-liner.
- Batch cross-directory writes to minimize sandbox override prompts.
- Do not create branches, install dependencies, or modify source code.
- Lane definitions come from CLAUDE.md or discovered clones — never hardcode lane names.
- After writing, read back each file to confirm it was written correctly.
