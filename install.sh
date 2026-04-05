#!/usr/bin/env bash
set -euo pipefail

SKILLS_DIR="${HOME}/.claude/skills"
REPO_DIR="$(cd "$(dirname "$0")" && pwd)"

mkdir -p "$SKILLS_DIR"

installed=0
skipped=0

for skill_dir in "$REPO_DIR"/*/; do
  [ -f "$skill_dir/SKILL.md" ] || continue
  name=$(basename "$skill_dir")
  target="$SKILLS_DIR/$name"

  if [ -L "$target" ] && [ "$(readlink "$target")" = "$skill_dir" ]; then
    echo "  skip  $name (already linked)"
    skipped=$((skipped + 1))
    continue
  fi

  if [ -e "$target" ]; then
    echo "  update  $name (replacing existing)"
    rm -rf "$target"
  fi

  ln -s "$skill_dir" "$target"
  echo "  link  $name -> $target"
  installed=$((installed + 1))
done

echo ""
echo "Done: $installed installed, $skipped skipped"
echo "Skills are available as slash commands in Claude Code."
