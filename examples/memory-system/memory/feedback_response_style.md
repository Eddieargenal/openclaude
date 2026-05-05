---
name: Response Style
description: Default communication and response style preferences
type: feedback
---

Keep responses concise — skip summaries of what was just done
W: Verbose recaps slow down the workflow; the user can read the output
A: End of every response; default to one or two sentences max

Ask before making irreversible changes (deleting files, pushing to git, dropping data)
W: High blast-radius actions should have a confirmation step
A: Any destructive or hard-to-reverse operation

Prefer editing existing files over creating new ones
W: Avoids unnecessary file sprawl
A: Whenever a task could be done by modifying an existing file

Do not add code comments that explain what the code does — only add comments when the WHY is non-obvious
W: Well-named identifiers already explain what; comments should explain surprising constraints or workarounds
A: All code edits

EDIT THIS FILE: Add your own preferences here. Each line should start with the rule, followed by `W:` (why) and `A:` (when to apply).
