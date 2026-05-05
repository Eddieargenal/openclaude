# OpenClaude — Eddieargenal Fork

This is a patched fork of [Gitlawb/openclaude](https://github.com/Gitlawb/openclaude) with fixes for reasoning models via OpenRouter and a second-brain memory system integrated into the launch wrapper.

---

## What This Fork Adds

Five bug fixes for OpenRouter reasoning models — see [`docs/openrouter-reasoning-models-fix.md`](docs/openrouter-reasoning-models-fix.md) for full details:

| Fix | Description |
|---|---|
| `reasoning` field support | MiniMax M2.7 uses `delta.reasoning` not `delta.reasoning_content` — both are now handled |
| Stream close fallback | Providers that send `finish_reason: null` no longer hang the TUI |
| MiniMax multi-turn context | `preserveReasoningContent: true` prevents reasoning context loss between turns |
| Gemini `stream_options` strip | Removes the field that caused Gemini to silently fail streaming |
| OpenRouter headers | Injects `HTTP-Referer` + `X-Title` to prevent bot-detection errors |

---

## Prerequisites

- **Node.js** ≥ 18
- **Bun** (for building from source) — [install](https://bun.sh)
- **Git**
- An **OpenRouter API key** — [openrouter.ai/keys](https://openrouter.ai/keys)

---

## Step 1 — Clone and Build

```bash
git clone https://github.com/Eddieargenal/openclaude.git
cd openclaude
PATH="$PATH:$HOME/.bun/bin" npm install
PATH="$PATH:$HOME/.bun/bin" npm run build
npm link
```

`npm link` makes `openclaude` available globally as a CLI command.

To rebuild after pulling updates:

```bash
PATH="$PATH:$HOME/.bun/bin" npm run build
```

---

## Step 2 — OpenRouter API Key

Get a key at [openrouter.ai/keys](https://openrouter.ai/keys), then add it to your shell profile (`~/.zshrc` or `~/.bashrc`):

```bash
export OPENROUTER_API_KEY="sk-or-..."
```

Reload the shell:

```bash
source ~/.zshrc
```

---

## Step 3 — Shell Launch Function

Add the `oc` function to your `~/.zshrc`. This function:
- Routes all API calls through OpenRouter
- Runs OpenClaude in bare mode (no Anthropic telemetry, no OAuth)
- Injects your memory system as a system prompt on every launch
- Grants full home-directory file access (required for the agent to work anywhere under `~`)

Replace `YOUR_USERNAME` with your macOS username (output of `whoami`):

```bash
oc() {
  local model="${OPENCLAUDE_MODEL:-google/gemini-2.0-flash-001}"
  local memory_dir="$HOME/.claude/projects/-Users-YOUR_USERNAME/memory"
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
  OPENAI_API_KEY="$OPENROUTER_API_KEY" \
  OPENAI_MODEL="$model" \
  openclaude --dangerously-skip-permissions --bare --add-dir "$HOME" \
    --append-system-prompt "$context" "$@"
}

# Usage:
#   oc                                              → launch with default model
#   OPENCLAUDE_MODEL=minimax/minimax-m2.7 oc        → launch with a different model
```

Reload after adding:

```bash
source ~/.zshrc
```

---

## Step 4 — Memory System

The memory system gives the agent persistent context across sessions. It lives at `~/.claude/` and is injected into every session via `--append-system-prompt` in the `oc` function.

### Directory structure

```
~/.claude/
├── CLAUDE.md                          # Global instructions for the agent
├── _system/
│   └── memory/
│       └── memory-rules.md            # Memory format and write rules
├── projects/
│   └── -Users-YOUR_USERNAME/
│       └── memory/
│           ├── MEMORY.md              # Index of all memory files
│           ├── user_role.md           # Who you are
│           ├── feedback_*.md          # Behavioral feedback memories
│           ├── project_*.md           # Ongoing project context
│           └── reference_*.md        # Pointers to external resources
└── skills/                            # Slash-command skill definitions
    ├── memory-write.md
    ├── memory-recall.md
    ├── audit-memory.md
    └── ...
```

### Create the base files

```bash
mkdir -p ~/.claude/projects/-Users-$(whoami)/memory
mkdir -p ~/.claude/_system/memory
mkdir -p ~/.claude/skills
```

**`~/.claude/CLAUDE.md`** — tells the agent about your memory system and available skills:

```markdown
# Second Brain Memory System
Governed memory at `~/.claude/`. Principles + format rules: `_system/memory/memory-rules.md` (load on demand).

## Memory Writing Rules (active every session)
- One line per fact; `W:` = why; `A:` = when to apply; no paragraph prose
- Skip preamble — start with the rule or fact directly
- Code blocks only when exact syntax is the memory (commands, queries)
- MEMORY.md entry descriptions: ≤8 words

## Skills
`/memory-write` `/memory-recall` `/audit-memory` `/snapshot-memory` `/promote-memory` `/recover-session` `/inspect-compaction` `/consolidate-memory`
```

**`~/.claude/projects/-Users-YOUR_USERNAME/memory/MEMORY.md`** — start empty, the agent will populate it:

```markdown
# Project Memory Index
```

**`~/.claude/_system/memory/memory-rules.md`** — memory governance rules. See the full file at [`docs/memory-rules-template.md`](docs/memory-rules-template.md) or use this minimal version:

```markdown
# Memory System Rules

## Content Format Rules
- One line per fact — no paragraph prose in memory bodies
- Use `W:` (why) and `A:` (when to apply) as inline labels
- Skip preamble sentences — start with the rule or fact directly
- Code blocks only when exact syntax is the memory
- MEMORY.md entry descriptions: ≤8 words
```

### Skills

Skills are markdown files in `~/.claude/skills/` that define slash commands. The agent calls them via `/skill-name`. You can start with the skills in this repo (if included) or let the agent create them as needed.

The memory skills used by this setup:

| Skill | Purpose |
|---|---|
| `/memory-write` | Save a new memory fact |
| `/memory-recall` | Retrieve memories by keyword or topic |
| `/audit-memory` | Check for stale or contradictory memories |
| `/snapshot-memory` | Capture current session state |
| `/promote-memory` | Promote a candidate memory to permanent |
| `/recover-session` | Recover context after a compaction event |
| `/consolidate-memory` | Merge duplicate or related memories |
| `/inspect-compaction` | Review compaction candidates |

---

## Step 5 — Launch

```bash
oc
```

To use a specific model:

```bash
OPENCLAUDE_MODEL=google/gemini-2.0-flash-001 oc
OPENCLAUDE_MODEL=deepseek/deepseek-chat-v3-0324 oc
OPENCLAUDE_MODEL=minimax/minimax-m2.7 oc
```

---

## Model Notes

| Model | Agentic use | Notes |
|---|---|---|
| `google/gemini-2.0-flash-001` | Yes (recommended) | Fast, reliable, full tool support |
| `deepseek/deepseek-chat-v3-0324` | Yes | Strong for coding tasks |
| `minimax/minimax-m2.7` | No | Does not support tool/function calling — use for plain chat only |

> MiniMax M2.7 does not support function calling. Since OpenClaude sends tool schemas on every request, it cannot be used for coding or agentic tasks. It works for bare conversational sessions.

---

## Debug Mode

To inspect the messages sent to the model (useful for debugging multi-turn issues):

```bash
OPENCLAUDE_DEBUG_MSGS=1 oc
```

This writes all outgoing message payloads to stderr.

---

## Updating

Pull upstream changes and rebuild:

```bash
git fetch origin
git merge origin/main
PATH="$PATH:$HOME/.bun/bin" npm run build
```

To also pull from this fork:

```bash
git fetch myfork
git merge myfork/main
PATH="$PATH:$HOME/.bun/bin" npm run build
```

---

## Security Notes

- `--dangerously-skip-permissions` disables all permission prompts. The agent can run any shell command without asking. This is intentional for a power-user setup but means a prompt-injected response could take local actions.
- `--add-dir $HOME` grants file tool access to your entire home directory.
- `--append-system-prompt` passes memory content as a CLI argument, which is visible to other same-user processes via `ps`. Acceptable on a single-user machine; be aware on shared systems.
- All Anthropic telemetry (Datadog, StatsIg, GrowthBook, transcript sharing) is stubbed out at build time. No conversation data is sent anywhere except your configured OpenRouter endpoint.

---

## Links

- Upstream repo: [Gitlawb/openclaude](https://github.com/Gitlawb/openclaude)
- Bug fix documentation: [`docs/openrouter-reasoning-models-fix.md`](docs/openrouter-reasoning-models-fix.md)
- OpenRouter: [openrouter.ai](https://openrouter.ai)
