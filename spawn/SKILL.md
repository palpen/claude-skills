---
name: spawn
version: 0.1.0
description: |
  Create a new feature clone for multi-clone parallel development. Clones
  the repo to <parent>/<repo>--<name>, creates a feature branch, copies
  env files with unique port, and installs dependencies. Two modes:
  direct (/spawn auth-refactor) or analyze (/spawn with no args to suggest
  workstream splits). Use when asked to "spawn", "new clone", "new
  workstream", "branch off", or "create a workspace".
allowed-tools:
  - Bash
  - Read
  - Write
  - Edit
  - Grep
  - Glob
  - AskUserQuestion
---

# Spawn — Create a Feature Clone

Create a new isolated clone of the current repo for parallel feature development.

## Modes

- **Direct:** `/spawn <feature-name>` — create a single clone for the named feature
- **Analyze:** `/spawn` with no args — scan the repo structure, suggest logical workstream splits, let the user pick which to create

## Steps

### 1. Orient — Identify the source repo

Run these in parallel:
- `git remote get-url origin` — the clone URL
- `git rev-parse --show-toplevel` — repo root path
- `basename $(git rev-parse --show-toplevel)` — repo directory name
- `git branch --show-current` — current branch

Derive the **base repo name** by stripping any `--<suffix>` from the directory name.
Example: `job_ai_risk_evaluator--backend` has base name `job_ai_risk_evaluator`.

Set `BASE_DIR` to the parent directory of the repo root (e.g., `~/Desktop`).
Set `SOURCE_DIR` to the current repo root.

### 2. Mode selection

If the user provided a feature name (e.g., `/spawn auth-refactor`), go to **Step 4 (Direct mode)**.

If no feature name was provided, go to **Step 3 (Analyze mode)**.

### 3. Analyze mode — Suggest workstream splits

#### 3a. Ask about investigation depth

Use `AskUserQuestion` to ask:
```
I can suggest workstream lanes two ways:

  1. Quick — heuristic split based on directory structure and project type
  2. Deep — investigate routes, actions, services, DB schema, and shared
     surfaces to propose domain-based lanes (supply/demand style splits
     that minimize cross-team file collisions)

Which approach? (1/2)
```

If the user picks **1**, go to **Step 3c (Quick heuristics)**.
If the user picks **2**, go to **Step 3b (Deep investigation)**.

#### 3b. Deep investigation

Perform a thorough codebase analysis to find domain-based ownership boundaries:

1. **Map all routes/pages** — find every page entry point and what it renders
2. **Map all server actions / API routes** — list every exported function and which routes call them
3. **Map services and data access** — which DB tables does each service touch
4. **Map components** — which pages use which components, identify shared vs. single-owner components
5. **Identify cross-cutting files** — files that multiple domains must touch (types, schemas, shared utils)
6. **Find the seams** — look for natural domain boundaries where files cluster together with minimal cross-references. Prefer domain splits (by user persona or business concern) over layer splits (frontend/backend/infra). Layer splits cause more merge conflicts because features span layers.

Produce a brief analysis:
```
Codebase analysis for <repo-name>:

  Tables: <list>
  Routes: <list with brief purpose>
  Action files: <list with function counts>

  Suggested domain lanes:
    1. --<name>  : <one-line description>
       Owns: <key files>
    2. --<name>  : <one-line description>
       Owns: <key files>
    3. --<name>  : <one-line description>
       Owns: <key files>

  Shared surfaces (collision risk): <files that span lanes>
  Main cross-lane seam: <the #1 file/module where lanes overlap>
```

Then go to **Step 3d (User choice)**.

#### 3c. Quick heuristics

1. **Check for CLAUDE.md / AGENTS.md** — look for a "Workstream Lanes" or "Workstream Boundaries" section. If defined, parse and use those.

2. **Check for monorepo markers** — look for:
   - Multiple `package.json` files (not in `node_modules`)
   - `lerna.json`, `pnpm-workspace.yaml`, `turbo.json`, `nx.json`
   - Top-level directories with their own build configs

3. **Heuristic directory analysis** — if no explicit workstreams found:
   - Detect project type: Next.js (`next.config.*`), Rails (`Gemfile` + `config/routes.rb`), Django (`manage.py`), Go (`go.mod`), generic
   - For Next.js/React: suggest splits like `frontend` (components, pages, hooks), `backend` (API routes, server logic), `infra` (config, deploy, CI)
   - For monorepos: suggest one clone per package/workspace
   - For any repo: look for natural directory clusters that map to concerns

Then go to **Step 3d (User choice)**.

#### 3d. User choice

1. **Check existing clones** — list `BASE_DIR/<base-repo-name>--*` directories to see what already exists. Don't suggest duplicates.

2. **Present suggestions** using `AskUserQuestion`:
   ```
   Suggested workstreams for <base-repo-name>:

   Existing clones:
     --backend (feat/backend, port 3002)

   Suggested new clones:
     1. --<name>  -> feat/<name> (<description>)
     2. --<name>  -> feat/<name> (<description>)
     3. --<name>  -> feat/<name> (<description>)

   Enter numbers to create (e.g., "1,2"), custom names (e.g., "supply,demand,platform"),
   or "skip":
   ```

   If the user enters custom names instead of numbers, use those names for the clones instead of the suggested names. This lets users override the naming while still benefiting from the analysis.

3. Proceed to Step 4 for each selected clone.

### 4. Direct mode — Create the clone

For the given feature name:

#### 4a. Validate

- Sanitize the feature name: lowercase, replace spaces with hyphens, strip special characters.
- Check that `BASE_DIR/<base-repo-name>--<feature-name>` does not already exist. If it does, stop and report.

#### 4b. Assign a port

Scan for used ports across all sibling clones:
```bash
for d in BASE_DIR/<base-repo-name>*; do
  grep '^PORT=' "$d/.env.local" "$d/web/.env.local" "$d/frontend/.env.local" 2>/dev/null
done
```
Find the highest port number in use and assign `highest + 1`. Default starting port is 3000 if no clones have PORT set.

Verify the assigned port is not actively in use: `lsof -ti:<port> 2>/dev/null`. If it is, increment and try again.

#### 4c. Clone

```bash
git clone <remote-url> BASE_DIR/<base-repo-name>--<feature-name>
```

Use the remote URL (not a local path) so the new clone gets a proper remote.

#### 4d. Create feature branch

```bash
cd <new-clone-dir>
git checkout -b feat/<feature-name>
```

#### 4e. Copy and adapt env files

Search for env files in the source clone. Check these locations in order:
- `.env.local`
- `web/.env.local`
- `frontend/.env.local`
- `app/.env.local`
- `.env`

For each env file found, copy it to the same relative path in the new clone, then modify ONLY variables that already exist:
- `PORT=<assigned-port>`
- `NEXT_PUBLIC_CLONE_NAME=<feature-name>` (if present)
- `NEXT_PUBLIC_BASE_URL=http://localhost:<assigned-port>` (if present)

Do NOT add variables that don't exist in the source file.

#### 4f. Install dependencies

Detect the project type and install:
- `web/package.json` exists: `cd web && npm install`
- `package.json` at root (no `web/`): `npm install`
- `frontend/package.json` exists: `cd frontend && npm install`
- `Gemfile` exists: `bundle install`
- `requirements.txt` or `pyproject.toml` exists: `pip install -r requirements.txt` or `pip install .`
- `go.mod` exists: `go mod download`
- `Cargo.toml` exists: `cargo fetch`

Prefer the most specific location (e.g., `web/` over root if both exist).

#### 4g. Update project docs (optional)

Check if `AGENTS.md` in the source clone contains a markdown table with columns matching "Clone", "Port", "Branch", or "URL".

If found, use `AskUserQuestion`: "AGENTS.md has a port table. Add a row for --<name>? (y/n)"

If yes, edit the table in the SOURCE clone's AGENTS.md (the new clone will pick it up on next sync).

### 5. Report

Print a summary:
```
Spawned: <base-repo-name>--<feature-name>
  Path:    <full-path>
  Branch:  feat/<feature-name>
  Port:    <port>
  Server:  cd <path>/web && npm run dev

Open this directory in a new Claude Code session to start working.
```

## Rules

- Never modify the source clone's code — only its AGENTS.md port table (with permission).
- Never switch branches in the source clone.
- If `git clone` fails (SSH key, network), suggest HTTPS URL as a fallback.
- If the user is in a `--<name>` clone, use the REMOTE URL to clone (not the local path).
- Branch naming is always `feat/<name>`.
- If creating multiple clones (from analyze mode), create them sequentially and report each one.
- Port assignment must be collision-free — always scan ALL sibling clones.
