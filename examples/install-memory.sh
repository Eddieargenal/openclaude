#!/usr/bin/env bash
# install-memory.sh — copy example memory system into ~/.claude/
# Run from the repo root: bash examples/install-memory.sh

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SOURCE="$SCRIPT_DIR/memory-system"
USERNAME="$(whoami)"
HOME_SLUG="$(echo "$HOME" | tr '/' '-')"
MEMORY_PROJECT_DIR="$HOME/.claude/projects/$HOME_SLUG/memory"

echo "Installing OpenClaude memory system for user: $USERNAME (home slug: $HOME_SLUG)"
echo ""

# Create directory structure
mkdir -p "$HOME/.claude/_system/memory"
mkdir -p "$MEMORY_PROJECT_DIR"
mkdir -p "$HOME/.claude/skills"

# CLAUDE.md
if [ -f "$HOME/.claude/CLAUDE.md" ]; then
  echo "[skip] ~/.claude/CLAUDE.md already exists — not overwriting"
  echo "       Review examples/memory-system/CLAUDE.md and merge manually if needed"
else
  cp "$SOURCE/CLAUDE.md" "$HOME/.claude/CLAUDE.md"
  echo "[ok]   ~/.claude/CLAUDE.md"
fi

# memory-rules.md
if [ -f "$HOME/.claude/_system/memory/memory-rules.md" ]; then
  echo "[skip] ~/.claude/_system/memory/memory-rules.md already exists"
else
  cp "$SOURCE/_system/memory/memory-rules.md" "$HOME/.claude/_system/memory/memory-rules.md"
  echo "[ok]   ~/.claude/_system/memory/memory-rules.md"
fi

# MEMORY.md index
if [ -f "$MEMORY_PROJECT_DIR/MEMORY.md" ]; then
  echo "[skip] $MEMORY_PROJECT_DIR/MEMORY.md already exists"
else
  cp "$SOURCE/memory/MEMORY.md" "$MEMORY_PROJECT_DIR/MEMORY.md"
  echo "[ok]   $MEMORY_PROJECT_DIR/MEMORY.md"
fi

# Example memory files
for f in "$SOURCE/memory/"*.md; do
  base="$(basename "$f")"
  [ "$base" = "MEMORY.md" ] && continue
  dest="$MEMORY_PROJECT_DIR/$base"
  if [ -f "$dest" ]; then
    echo "[skip] $dest already exists"
  else
    cp "$f" "$dest"
    echo "[ok]   $dest"
  fi
done

# Skill files
for skill_dir in "$SOURCE/skills"/*/; do
  skill_name="$(basename "$skill_dir")"
  dest_dir="$HOME/.claude/skills/$skill_name"
  if [ -d "$dest_dir" ]; then
    echo "[skip] ~/.claude/skills/$skill_name/ already exists"
  else
    mkdir -p "$dest_dir"
    cp "$skill_dir/SKILL.md" "$dest_dir/SKILL.md"
    echo "[ok]   ~/.claude/skills/$skill_name/SKILL.md"
  fi
done

echo ""
echo "Done. Memory system installed to ~/.claude/"
echo ""
echo "Next steps:"
echo "  1. Edit $MEMORY_PROJECT_DIR/user_role.md"
echo "     — replace the placeholder with a description of yourself"
echo "  2. Add the oc() function to ~/.zshrc or ~/.bashrc (see README-FORK.md Step 3)"
echo "  3. Set your OpenRouter API key:"
echo "     export OPENROUTER_API_KEY=sk-or-..."
echo "  4. Reload your shell: source ~/.zshrc  (or source ~/.bashrc on Linux)"
echo "  5. Launch: oc"
