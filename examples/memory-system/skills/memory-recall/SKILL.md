---
name: memory-recall
description: Explicit retrieval gateway for the memory system. Supports exact-key, keyword, temporal, and relational queries with token budgets.
---

# Memory Recall

The read-side gateway for memory retrieval. Counterpart to memory-write.

## Arguments
- `query`: A natural language query or a normalized key

## Step 1 — Query Classification
Determine query type:
- **exact-key**: Input looks like a normalized key (lowercase, hyphenated)
- **keyword**: Natural language describing a topic
- **temporal**: Asks about changes ("since last session", "recently", "last week")
- **relational**: Asks about connections ("everything related to X", "what depends on Y")

## Step 2 — Execute Retrieval

### exact-key
1. Grep `_system/memory/indexes/key-index.jsonl` for the key
2. If found, read the record at file:line from the index entry
3. If not found, fall back to keyword search splitting key on hyphens

### keyword
1. Extract 2-4 search terms from the query
2. Grep `_system/memory/indexes/keyword-index.jsonl` for each term
3. Score candidates: keys matching multiple terms rank higher
4. Resolve top 5 via key-index.jsonl
5. Read top 3 records by score

### temporal
1. Read last N entries from `runtime/sessions/diff-log.jsonl`
2. Collect keys from keys_created, keys_updated, decisions_made
3. Resolve via key-index.jsonl
4. Present as timeline

### relational
1. Identify anchor key from query
2. Look up in `_system/memory/indexes/relations.jsonl`
3. Collect related keys and relation_type
4. Resolve each via key-index.jsonl
5. Group by relation_type

## Step 3 — Token Budget
- Single query: max 800 tokens
- Relational query: max 1,200 tokens
- Temporal query: max 600 tokens
- If over budget: summarize to key + one-line value + status
- Never silently truncate — indicate summarization

## Step 4 — Result Formatting
Present: key, category, current value (compact), status, related keys (one-line pointers), estimated tokens consumed.
If 5+ results: summarize and ask whether to expand.

## Step 5 — Nothing Found
If all retrieval paths return empty:
1. Report: "No memory found for: [query]"
2. Suggest the most likely category file to check manually
3. Ask whether to create a new record
4. Do NOT fabricate answers from general knowledge

## Step 6 — Index Staleness Handling
If an index entry points to wrong location:
1. Warn: "Index stale for key [X], falling back to scan"
2. Scan expected category file linearly
3. If found elsewhere, return result and flag index for rebuild
4. Log staleness to runtime/logs/

## Step 7 — Retrieval Logging
Append to `runtime/logs/retrieval-log.jsonl`:
- timestamp, session_id, query, query_type, keys_found, keys_presented, tokens_consumed, index_used, stale_entries, result
