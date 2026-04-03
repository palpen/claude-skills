---
name: disk-usage
version: 0.1.0
description: |
  Scan disk usage across all folders in the home directory, organize by size,
  break down heavy directories, and flag the largest files and caches that
  can be safely deleted. Never executes any delete operations.
  Use when asked to "check disk usage", "disk space", "what's using space",
  "clean up disk", or "free up space".
allowed-tools:
  - Bash
  - Read
---

# Disk Usage Report

Scan the user's home directory and produce a structured disk usage report.
**NEVER delete, remove, or clean anything.** Report only.

## Steps

Run these in parallel where possible:

### 1. Top-level folder sizes

```bash
du -sh ~/*/ 2>/dev/null | sort -hr | head -30
```

```bash
du -sh ~/.* 2>/dev/null | sort -hr | head -20
```

### 2. Break down the largest folders

For the top 2-3 largest folders from Step 1, drill one level deeper:

```bash
du -sh ~/Library/*/ 2>/dev/null | sort -hr | head -15
```

```bash
du -sh ~/Library/Caches/*/ 2>/dev/null | sort -hr | head -10
```

```bash
du -sh ~/Library/Application\ Support/*/ 2>/dev/null | sort -hr | head -10
```

Adapt these paths based on what Step 1 reveals — if `Library/` isn't the biggest,
drill into whatever is.

### 3. Find large files (>50 MB)

```bash
find ~ -not -path '*/Library/*' -not -path '*/.Trash/*' -type f -size +50M 2>/dev/null | head -30
```

For each file found, show its size with `du -sh`.

### 4. Find reclaimable development artifacts

Run these in parallel:

**node_modules directories:**
```bash
find ~/Desktop ~/Documents ~/personal -name "node_modules" -type d -maxdepth 4 2>/dev/null | while read d; do du -sh "$d" 2>/dev/null; done | sort -hr
```

**.next / build caches:**
```bash
find ~/Desktop ~/Documents ~/personal -name ".next" -type d -maxdepth 4 2>/dev/null | while read d; do du -sh "$d" 2>/dev/null; done | sort -hr
```

**Python virtual environments:**
```bash
find ~/Desktop ~/Documents ~/personal \( -name "venv" -o -name ".venv" \) -type d -maxdepth 4 2>/dev/null | while read d; do du -sh "$d" 2>/dev/null; done | sort -hr
```

### 5. Check common caches

```bash
du -sh ~/.npm/_cacache 2>/dev/null
du -sh ~/.cache/*/ 2>/dev/null | sort -hr
```

## Output format

Present the results as a structured report with these sections:

### Section 1: Total by top-level folder
A markdown table sorted by size descending, with a "Notes" column for context
(e.g., "All your project repos", "npm cache").

### Section 2: Breakdown of largest folders
Drill-down tables for the heaviest directories (Library/, Desktop/, etc.).

### Section 3: Development artifacts
Separate tables for node_modules, .next caches, and Python venvs with per-project sizes.

### Section 4: Candidates for deletion
Split into three categories:

**Safe to clear — caches:** Items that can be rebuilt automatically (npm cache,
pip cache, Homebrew cache, browser caches, old CLI versions). Include the command
to clear each one.

**Safe to clear — rebuild with install:** node_modules and build caches for
inactive projects. Note that `npm install` / `pip install` will restore them.

**Worth reviewing:** Large files or app data that may or may not be needed
(old videos, unused app data, dormant project venvs). Frame as questions
("Still using this project?", "Move to external storage?").

### Section 5: Quick wins summary
A table showing action, space recovered, for the top opportunities.

## Rules

- **NEVER execute any delete, rm, clean, or purge commands.** This is a read-only audit.
- Show exact commands the user would run to clear each item, but do not run them.
- Round sizes to human-readable units (GB, MB).
- If a folder doesn't exist or returns errors, skip it silently.
- Adapt the scan paths to the user's actual directory structure — the paths above
  are starting points, not the only places to check.
