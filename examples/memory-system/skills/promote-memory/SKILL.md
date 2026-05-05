---
name: promote-memory
description: Review promotion candidates from logs, checkpoints, and compaction outputs. Promote validated items to category memory or bootstrap.
disable-model-invocation: true
---

# Promote Memory

Review and promote memory candidates from the promotion queue.

## Arguments
- `file` (optional): Specific candidate file to review. If omitted, scans all of runtime/promotions/

## Behavior
1. Read candidate files from runtime/promotions/
2. For each candidate:
   - Display: key, value, source, confidence, promotion_gate status
   - Classify: durable vs operational vs episodic
   - Check duplication against existing category records
   - Check for contradictions with existing validated records
3. For approved candidates:
   - Route through memory-write gateway (not direct file write)
   - Update promotion_gate to: approved
   - Move processed candidate file to archive
4. For rejected candidates:
   - Update promotion_gate to: rejected
   - Preserve in archive with rejection reason
5. Update changelog in archive/changelogs/
6. Rebuild indexes after all promotions

## Constraints
- Never auto-promote without review
- compaction-sourced candidates always require human review
- Never promote low-confidence inferences to validated
- Keep bootstrap lean — promote to Tier-1 only when clearly justified
