---
name: audit-memory
description: Review the health of the second-brain memory system. Measures bootstrap size, detects drift, checks staleness, inspects unresolved backlog, finds contradictions, and analyzes retrieval patterns.
disable-model-invocation: true
---

# Audit Memory

Comprehensive health check of the second-brain memory system.

## Behavior

### Bootstrap Size
- Count words in MEMORY.md + current-handoff.md + next-session.md
- Estimate tokens: word_count * 1.3
- Report band: Ideal (<3k), Warning (3-5k), Audit (5-7k), Blocked (>7k)

### Category Health
- Count records per category file
- Check for missing required fields (key, value, status)
- Check behavioral records for subtype field
- Report category sizes

### Cross-File Contradiction Detection
1. **Key collision scan**: Find keys appearing in multiple categories with different values
2. **Semantic conflict scan**: Check decisions vs behavioral rules for contradictions
3. **Outcome contradiction scan**: Flag decisions that persist despite failure outcomes

### Index Staleness
- Verify key-index.jsonl entries point to valid locations
- Check keyword-index.jsonl coverage
- Verify relations.jsonl references exist
- Report stale entry count and suggest rebuild

### Retrieval Pattern Analysis (from retrieval-log.jsonl)
- Most frequently retrieved keys (bootstrap promotion candidates)
- Queries returning not-found (knowledge gaps)
- Average tokens consumed per retrieval
- Index staleness rate

### Decay Analysis
- Flag cooling records (not accessed in 5+ sessions)
- Flag cold records (not accessed in 15+ sessions, access_count < 3)
- List protected records exempt from decay
- Generate decay candidates for human review

### Source Tagging Compliance
- Flag records missing source field
- Flag agent-inferred records that reached validated without confirmation

### Consolidation Check
- If 10+ sessions since last consolidation, recommend running consolidate-memory

### Output
Write audit report to docs/second-brain/audits/audit-{TIMESTAMP}.md

## Constraints
- Read-only — never modify memory files
- Report issues with severity: info, warning, critical
- Suggest fixes but do not auto-apply
