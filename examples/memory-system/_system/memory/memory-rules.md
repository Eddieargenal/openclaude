# Memory System Rules

## System Principles
- `_system/memory/MEMORY.md` and handoff files are the bootstrap control surface
- Category files load on demand — never at bootstrap
- Unresolved is first-class — never bury ambiguity under pending
- All memory changes flow through the `/memory-write` skill gateway
- Compaction creates candidates, never durable truth — promotion is a separate gate
- Pointers preferred over bulky repeated context
- Explicit repository memory files are authoritative — not conversational memory
- Source tagging required on all writes (poisoning defense)
- Memory decays over time if not accessed — forgetting is intentional
- Session reflection generates revision candidates from outcomes

## Content Format Rules
- One line per fact — no paragraph prose in memory bodies
- Use `W:` (why) and `A:` (when to apply) as inline labels, not bold section headers
- Skip preamble sentences — start with the rule or fact directly
- Code blocks only when exact syntax is the memory (commands, queries, not illustration)
- MEMORY.md entry descriptions: ≤8 words

## Write Rules
- All writes go through memory-write gateway
- Source tagging required: user-stated | user-confirmed | agent-inferred | tool-output | compaction | consolidation
- agent-inferred capped at truth_state: proposed without confirmation
- compaction records capped at proposed with requires_human_review: true
- Contradictions to validated records route to unresolved
- Atomic writes: intent → write → index → relations → mark applied
- Rollback preserved in runtime/recovery/rollback.jsonl

## Bootstrap Rules
- Under 3,000 tokens: ideal
- 3,000–5,000 tokens: warning
- Above 5,000 tokens: audit/cleanup
- Above 7,000 tokens: block new Tier-1 additions
- Measurement: word_count * 1.3

## Retrieval Rules
- Single query budget: max 800 tokens
- Relational query budget: max 1,200 tokens
- Temporal query budget: max 600 tokens
- Never fabricate answers from general knowledge
- Log all retrievals to runtime/logs/retrieval-log.jsonl

## Truth States
proposed → observed → validated → (disputed | superseded | archived)

## Behavioral Precedence
1. correction-rule
2. session-directive
3. explicit-preference
4. project-specific-rule
5. assistant-commitment
6. inferred-preference

## Decay Lifecycle
active → cooling (5+ sessions unused) → cold (15+ sessions, access_count < 3) → forgotten (approved removal)

## Protected from Decay
- validated + high confidence
- governance/compliance/security tagged
- 3+ inbound relations
- correction-rules
