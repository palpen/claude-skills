# claude-skills

Custom [Claude Code](https://claude.com/claude-code) skills for personal productivity.

## Skills

### `/tax-prep` — Canadian Tax Preparation Assistant

Reads all your tax documents from a folder, classifies them against the full CRA taxonomy, cross-references for missing documents, flags audit risks and optimization opportunities, and generates a comprehensive filing plan with a step-by-step checklist.

**What it does:**
1. Scans and classifies every document (T4, T5, T3, T2202, receipts, etc.)
2. Identifies missing documents based on your filing situation
3. Flags red flags (over-contributions, foreign property reporting, audit triggers)
4. Finds optimization opportunities (RRSP strategy, pension splitting, spousal credit allocation, medical expense window)
5. Generates a detailed income/deduction/credit summary with tax estimates
6. Produces a step-by-step filing checklist with every required form and schedule
7. Creates an accountant-ready summary document

**Usage:**
```
/tax-prep
```

Then point it at your folder of scanned tax documents (PDFs, images).

## Installation

### Option 1: Symlink (recommended)

Clone this repo, then symlink each skill into your Claude Code skills directory:

```bash
git clone https://github.com/YOUR_USERNAME/claude-skills.git
ln -sf "$(pwd)/claude-skills/tax-prep" ~/.claude/skills/tax-prep
```

### Option 2: Copy

Copy the skill directory directly:

```bash
cp -r tax-prep ~/.claude/skills/tax-prep
```

## Adding New Skills

Each skill lives in its own directory with a `SKILL.md` file. See the [Claude Code documentation](https://docs.anthropic.com/en/docs/claude-code) for the skill file format.

## License

MIT
