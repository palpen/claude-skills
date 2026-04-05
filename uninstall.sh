#!/usr/bin/env bash
set -euo pipefail

SKILLS_DIR="${HOME}/.claude/skills"
REPO_DIR="$(cd "$(dirname "$0")" && pwd)"

removed=0

for skill_dir in "$REPO_DIR"/*/; do
  [ -f "$skill_dir/SKILL.md" ] || continue
  name=$(basename "$skill_dir")
  target="$SKILLS_DIR/$name"

  if [ -L "$target" ] && [ "$(readlink "$target")" = "$skill_dir" ]; then
    rm "$target"
    echo "  unlink  $name"
    removed=$((removed + 1))
  fi
done

echo ""
echo "Done: $removed removed"
