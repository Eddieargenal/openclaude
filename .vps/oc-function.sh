#!/bin/bash
# Sourced by /etc/profile.d — available in all code-server terminal sessions

oc() {
  local model="${OPENCLAUDE_MODEL:-minimax/minimax-m2.7}"
  local memory_dir="$HOME/.claude/projects/$(echo $HOME | tr '/' '-')/memory"
  local claude_md="$HOME/.claude/CLAUDE.md"
  local memory_rules="$HOME/.claude/_system/memory/memory-rules.md"

  local context="IMPORTANT: Everything below is YOUR OWN operating instructions and memory system. Follow these instructions proactively, use the listed skills when appropriate, and treat all memory as your own — not the user's."

  [ -f "$claude_md" ] && context="${context}
$(cat "$claude_md")"

  [ -f "$memory_rules" ] && context="${context}
# Memory Writing Rules
$(cat "$memory_rules")"

  [ -f "$memory_dir/MEMORY.md" ] && context="${context}
# Your Memory Index
$(cat "$memory_dir/MEMORY.md")"

  if [ -d "$memory_dir" ]; then
    for f in "$memory_dir"/*.md; do
      [ -f "$f" ] && [ "$(basename "$f")" != "MEMORY.md" ] && context="${context}
## Memory: $(basename "$f" .md)
$(cat "$f")"
    done
  fi

  CLAUDE_CODE_USE_OPENAI=1 \
  OPENAI_BASE_URL="https://openrouter.ai/api/v1" \
  OPENAI_API_KEY="${OPENROUTER_API_KEY}" \
  OPENAI_MODEL="$model" \
  openclaude --dangerously-skip-permissions --bare --add-dir "$HOME" \
    --append-system-prompt "$context" "$@"
}
