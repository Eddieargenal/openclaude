---
name: snapshot-memory
description: Create a timestamped snapshot of bootstrap memory, category files, and runtime artifacts before risky changes or cleanup.
disable-model-invocation: true
---

# Snapshot Memory

Create a timestamped snapshot of the memory system before risky operations.

## Arguments
- `reason` (optional): Why this snapshot is being taken

## Behavior
1. Create snapshot directory: `_system/memory/archive/snapshots/snapshot-{TIMESTAMP}/`
2. Copy all Tier-1 files (MEMORY.md, current-handoff.md, next-session.md)
3. Copy all category files from `_system/memory/categories/`
4. Copy index files from `_system/memory/indexes/`
5. Optionally include active session journal if one exists
6. Write a manifest.md with:
   - timestamp
   - reason (from argument or "manual snapshot")
   - list of files included
   - file sizes

## Constraints
- NEVER delete originals
- NEVER modify source files
- Always write a manifest
- Support human-reviewable restoration

## Failure Behavior
- If a source file is missing, note it in the manifest and continue
- If the snapshot directory cannot be created, report error and stop
