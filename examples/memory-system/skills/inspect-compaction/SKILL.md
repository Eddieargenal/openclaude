---
name: inspect-compaction
description: Review the latest compaction extraction artifacts manually.
disable-model-invocation: true
---

# Inspect Compaction

Review compaction artifacts for promotion decisions.

## Behavior
1. List all files in runtime/compaction/
2. For each artifact:
   - Display: timestamp, extraction type, candidate count
   - Summarize candidates with key, value, confidence
3. Categorize each candidate as:
   - promotion-safe: validated, stable, non-duplicate
   - unresolved: ambiguous, contradictory, or low-confidence
   - archive-only: episodic, already captured elsewhere
4. Recommend next steps for each category

## Constraints
- Read-only — never modify compaction artifacts
- Never auto-promote
- Flag ambiguous candidates explicitly
