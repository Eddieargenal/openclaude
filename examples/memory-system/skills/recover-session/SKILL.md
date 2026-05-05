---
name: recover-session
description: Recover memory state after crash, interruption, stale session, or partial write failure.
disable-model-invocation: true
---

# Recover Session

Recover from interrupted or failed sessions.

## Behavior
1. Inspect active session journals in runtime/sessions/active/
2. Inspect write-intents.jsonl for status: queued entries
3. For each queued intent:
   - Display: intent_id, target_key, operation, timestamp
   - Assess if safe to replay
   - Mark as reviewed (human decides to apply or skip)
4. Inspect recovery artifacts in runtime/recovery/ for failure files
5. Rebuild provisional handoff from available state
6. Move unverifiable items to unresolved with tag: recovery-unverifiable
7. Write recovery notes to archive

## Constraints
- Never auto-apply queued intents in beginner profile
- Present recovery options for human decision
- Preserve all evidence
- Move stale journals to archive
