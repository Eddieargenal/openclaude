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

### Required software

| Tool | Version | Purpose |
|---|---|---|
| **Node.js** | ≥ 18 | Runtime for the CLI |
| **npm** | bundled with Node | Package manager and `npm link` |
| **Bun** | latest | Build tool (compiles TypeScript source) |
| **Git** | any recent | Clone the repo |
| **ripgrep** (`rg`) | any | File search tool used by the agent |

### macOS

```bash
# Install Homebrew if you don't have it
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# Install Node.js, Git, and ripgrep
brew install node git ripgrep

# Install Bun
curl -fsSL https://bun.sh/install | bash

# Reload your shell so bun is on PATH
source ~/.zshrc
```

Verify everything is installed:

```bash
node --version   # should print v18 or higher
npm --version
bun --version
git --version
rg --version
```

### Linux (Debian / Ubuntu)

```bash
# Install Node.js 20 via NodeSource
curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
sudo apt-get install -y nodejs git ripgrep

# Install Bun
curl -fsSL https://bun.sh/install | bash

# Reload your shell so bun is on PATH
source ~/.bashrc
```

### Linux (Fedora / RHEL / CentOS)

```bash
# Install Node.js 20 via NodeSource
curl -fsSL https://rpm.nodesource.com/setup_20.x | sudo bash -
sudo dnf install -y nodejs git ripgrep

# Install Bun
curl -fsSL https://bun.sh/install | bash

source ~/.bashrc
```

### OpenRouter API key

Get a free key at [openrouter.ai/keys](https://openrouter.ai/keys). Many models have a free tier — no credit card required to get started.

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
  local memory_dir="$HOME/.claude/projects/$(echo $HOME | tr '/' '-')/memory" # works on macOS and Linux automatically
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

The memory system gives the agent persistent context across sessions. It lives at `~/.claude/` and is injected on every launch via `--append-system-prompt` in the `oc` function. All the files you need are included in this repo under `examples/memory-system/`.

### Install with one command

From the repo root:

```bash
bash examples/install-memory.sh
```

The script:
- Creates all required directories under `~/.claude/`
- Copies `CLAUDE.md`, `memory-rules.md`, the memory index, example memory files, and all 8 skill definitions
- Skips any file that already exists — safe to re-run
- Prints your exact next steps at the end with your username pre-filled

### What gets installed

```
~/.claude/
├── CLAUDE.md                              # Global agent instructions
├── _system/
│   └── memory/
│       └── memory-rules.md               # Memory format and governance rules
├── projects/
│   └── -Users-yourname/  (macOS) or -root/ or -home-yourname/ (Linux)
│       └── memory/
│           ├── MEMORY.md                 # Index of all memory files
│           ├── user_role.md              # Who you are — edit this first
│           ├── project_setup.md          # Setup checklist the agent tracks
│           └── feedback_response_style.md # Default communication preferences
└── skills/
    ├── memory-write/SKILL.md             # Save a new memory fact
    ├── memory-recall/SKILL.md            # Retrieve memories by keyword or topic
    ├── audit-memory/SKILL.md             # Check for stale or contradictory memories
    ├── snapshot-memory/SKILL.md          # Snapshot memory before risky changes
    ├── promote-memory/SKILL.md           # Promote a candidate memory to permanent
    ├── recover-session/SKILL.md          # Recover context after a crash or compaction
    ├── consolidate-memory/SKILL.md       # Merge duplicate or related memories
    └── inspect-compaction/SKILL.md       # Review compaction candidates
```

### After installing

**Edit `user_role.md`** — this is the most important step. Open it and replace the placeholder with a description of yourself:

```bash
# The path is derived from your $HOME — e.g. /root → -root, /Users/eddie → -Users-eddie
nano ~/.claude/projects/$(echo $HOME | tr '/' '-')/memory/user_role.md
```

Examples of what to write:
- `User is a software engineer working primarily in Python and TypeScript`
- `User is a small business owner managing an e-commerce store`
- `User is a student learning programming for the first time`

The agent reads this on every session start to tailor its responses to you.

**Optionally edit `feedback_response_style.md`** to add or remove communication preferences. The defaults are sensible but you can tune them.

### How memory grows over time

The agent will add new memory files to `~/.claude/projects/$(echo $HOME | tr '/' '-')/memory/` as it learns things about you and your projects. Each file has a frontmatter header (`type: user | feedback | project | reference`) and one-line facts. The `MEMORY.md` index is updated automatically to point to each new file.

Skills are slash commands you can invoke inside a session:

| Skill | What it does |
|---|---|
| `/memory-write` | Save a fact the agent should remember |
| `/memory-recall` | Retrieve memories by keyword or topic |
| `/audit-memory` | Health check — detect stale or contradictory memories |
| `/snapshot-memory` | Snapshot memory before risky changes |
| `/promote-memory` | Promote a candidate memory to permanent |
| `/recover-session` | Recover context after a crash or compaction event |
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

## VPS Deployment (Docker + code-server)

This fork includes a Docker setup that runs OpenClaude inside a [code-server](https://github.com/coder/code-server) container — a browser-accessible VS Code with a persistent terminal. This lets you run `oc` from any device without installing anything locally.

The files are in `.vps/` and `Dockerfile.vps` in the repo root.

### Prerequisites

- A Linux VPS (Debian/Ubuntu recommended)
- Docker + Docker Compose v2
- A reverse proxy (Traefik, Nginx, Caddy) to expose code-server over HTTPS — or use Cloudflare Tunnel

Install Docker on Debian/Ubuntu:

```bash
curl -fsSL https://get.docker.com | sh
sudo usermod -aG docker $USER
```

### Step 1 — Set up the directory structure on the VPS

```bash
mkdir -p ~/docker/openclaude/source/.vps
mkdir -p ~/docker/openclaude/config
mkdir -p ~/docker/openclaude/claude-memory
```

### Step 2 — Copy the repo source to the VPS

From your local machine (inside the cloned repo):

```bash
# Copy built artifacts and Docker files to the VPS
scp -r dist/ bin/ package.json README.md node_modules/ \
    Dockerfile.vps .vps/ \
    USER@YOUR_VPS_IP:~/docker/openclaude/source/
```

Or clone the fork directly on the VPS and build there:

```bash
# On the VPS
git clone https://github.com/Eddieargenal/openclaude.git ~/docker/openclaude/source
cd ~/docker/openclaude/source
PATH="$PATH:$HOME/.bun/bin" npm install
PATH="$PATH:$HOME/.bun/bin" npm run build
```

### Step 3 — Create the .env file

```bash
cat > ~/docker/openclaude/.env <<'EOF'
OPENROUTER_API_KEY=sk-or-...
EOF
```

Replace `sk-or-...` with your actual OpenRouter API key. This file is read by Docker Compose and never committed to git.

### Step 4 — Copy docker-compose.yml

```bash
cp ~/docker/openclaude/source/.vps/docker-compose.yml ~/docker/openclaude/docker-compose.yml
```

### Step 5 — Install the memory system

```bash
# Run the install script targeting the claude-memory directory
# The container runs as root, so HOME inside the container is /root → slug is -root
mkdir -p ~/docker/openclaude/claude-memory/projects/-root/memory
mkdir -p ~/docker/openclaude/claude-memory/_system/memory
mkdir -p ~/docker/openclaude/claude-memory/skills

# Copy base files
cp ~/docker/openclaude/source/examples/memory-system/CLAUDE.md \
   ~/docker/openclaude/claude-memory/CLAUDE.md

cp ~/docker/openclaude/source/examples/memory-system/_system/memory/memory-rules.md \
   ~/docker/openclaude/claude-memory/_system/memory/memory-rules.md

cp ~/docker/openclaude/source/examples/memory-system/memory/*.md \
   ~/docker/openclaude/claude-memory/projects/-root/memory/

# Copy all skills
for skill_dir in ~/docker/openclaude/source/examples/memory-system/skills/*/; do
  skill_name="$(basename "$skill_dir")"
  mkdir -p ~/docker/openclaude/claude-memory/skills/$skill_name
  cp "$skill_dir/SKILL.md" ~/docker/openclaude/claude-memory/skills/$skill_name/SKILL.md
done

# Fix permissions so the container (root) can write
chmod -R a+rX ~/docker/openclaude/claude-memory
```

> **Note:** The container runs as `root`, so `$HOME` inside is `/root` and the memory slug is `-root`. This is already accounted for in the `oc-function.sh` which uses a dynamic path.

### Step 6 — Build and start

```bash
cd ~/docker/openclaude
docker compose build
docker compose up -d
```

### Step 7 — Edit user_role.md

```bash
nano ~/docker/openclaude/claude-memory/projects/-root/memory/user_role.md
```

Replace the placeholder text with a description of yourself. This is the most important personalisation step.

### Step 8 — Access code-server

Point your reverse proxy or Cloudflare Tunnel at the container's port `8443`. Open the URL in your browser, enter the password (set via `PASSWORD` env var in docker-compose — defaults to `openclaude`), and open a terminal. Run `oc` to launch.

To change the password, edit `docker-compose.yml`:

```yaml
environment:
  - PASSWORD=your-strong-password
  - OPENROUTER_API_KEY=${OPENROUTER_API_KEY}
```

### Host directory layout

```
~/docker/openclaude/
├── docker-compose.yml       # copied from .vps/
├── .env                     # your API key — never commit this
├── source/                  # repo source + built dist/
│   ├── Dockerfile.vps
│   ├── .vps/
│   ├── dist/
│   └── ...
├── config/                  # code-server user data (extensions, settings)
└── claude-memory/           # mounted to /root/.claude inside the container
    ├── CLAUDE.md
    ├── _system/memory/memory-rules.md
    ├── projects/-root/memory/
    │   ├── MEMORY.md
    │   ├── user_role.md
    │   └── ...
    └── skills/
        └── memory-write/ memory-recall/ ...
```

Memory persists across container restarts because `claude-memory/` is a bind mount — not stored inside the container.

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
