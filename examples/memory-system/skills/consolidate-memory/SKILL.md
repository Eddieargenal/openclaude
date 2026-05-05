---
name: consolidate-memory
description: Analyze episodic logs across multiple sessions to discover recurring patterns and distill them into semantic memory candidates.
disable-model-invocation: true
---

# Consolidate Memory

Cross-session pattern detection and semantic memory distillation.

## Arguments
- `sessions` (optional): Number of sessions to analyze (default: 10)

## Behavior
1. Read last N session journals from archive/sessions/ and runtime/sessions/active/
2. Read diff-log.jsonl for the same session range
3. Identify patterns:
   - **recurring-access**: Keys accessed/updated in 3+ sessions
   - **recurring-decision**: Decisions revisited or reversed
   - **recurring-question**: Questions that recurred across sessions
   - **recurring-procedure**: Procedures executed multiple times
   - **recurring-correction**: Behavioral corrections applied repeatedly
4. For each pattern, generate a consolidation candidate:
   - pattern_type, evidence_sessions, proposed_key, proposed_category
   - proposed_value, confidence (low/medium/high), source: consolidation
5. Write candidates to runtime/promotions/ with promotion_gate: pending
6. Report summary of patterns found and candidates generated

## Constraints
- NEVER write directly to category files
- Candidates only — promotion is a separate gate
- Minimum 3 sessions of evidence for medium confidence
- Minimum 5 sessions for high confidence
