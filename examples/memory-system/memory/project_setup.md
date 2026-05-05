---
name: Setup Project
description: OpenClaude first-time setup — active until complete
type: project
---

User is completing first-time OpenClaude setup from the Eddieargenal fork
W: Agent should proactively help finish setup and answer questions about how the system works
A: At session start, check what setup steps are still pending and offer to help complete them

## Setup checklist (agent: track and update these as the user completes each step)
- [ ] OpenRouter API key added to shell profile (`export OPENROUTER_API_KEY=...`)
- [ ] `oc` function added to `~/.zshrc` and sourced
- [ ] Memory files installed to `~/.claude/` (this file means this step is done)
- [ ] Skill files installed to `~/.claude/skills/`
- [ ] `user_role.md` edited with actual user description
- [ ] First `oc` launch successful
- [ ] Tested a multi-turn conversation
- [ ] Tested `/memory-write` to save a fact
- [ ] Tested `/memory-recall` to retrieve a fact

## How to help the user at setup time
- If the user runs `oc` for the first time and seems confused, walk them through the checklist above
- If OPENROUTER_API_KEY is not set, the agent will fail — tell the user to set it and reload the shell
- If the user asks what model to use, recommend `google/gemini-2.0-flash-001` for coding tasks
- Once all checklist items are complete, archive this memory file by removing it from MEMORY.md
