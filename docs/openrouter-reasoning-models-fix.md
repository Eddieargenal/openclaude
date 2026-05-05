# Bug Fix: OpenRouter Reasoning Models & Streaming Hang

## Summary

Two bugs prevented OpenClaude from working with reasoning models (MiniMax M2.7, DeepSeek, etc.) and Gemini models via OpenRouter. This document describes the root causes and the fixes applied.

---

## Bug 1: Streaming hang on first message (all models via OpenRouter)

### Symptom
The interactive TUI spinner turns orange then red and never produces a response. The `-p` (print) mode works fine with the same model.

### Root Cause
`openaiShim.ts` appends `stream_options: { include_usage: true }` to every streaming request sent to a remote provider:

```typescript
// openaiShim.ts ~line 1603
if (params.stream && !isLocalProviderUrl(request.baseUrl)) {
  body.stream_options = { include_usage: true }
}
```

Providers like Gemini (`google/gemini-2.0-flash-001` via OpenRouter) do not support the `stream_options` field. When it is present, the provider silently fails to stream a valid response. The `readWithTimeout()` reader then waits indefinitely (120s timeout), causing the spinner to hang and eventually turn red.

The `-p` mode uses `streaming: false` and never sets `stream_options`, which is why it works.

### Fix
Add `stream_options` to the `removeBodyFields` list for providers that don't support it. In `src/integrations/runtimeMetadata.ts`, add a Gemini/Google block inside `inferRemoteModelOpenAIShimConfig()`:

```typescript
if (normalizedModel.includes('gemini') || normalizedModel.startsWith('google/')) {
  return {
    maxTokensField: 'max_tokens',
    removeBodyFields: ['store', 'stream_options'],
  }
}
```

The `removeBodyFields` array is applied at line 1626 in `openaiShim.ts`, after `stream_options` is set, so it cleanly strips it before the request is sent.

**File changed:** `src/integrations/runtimeMetadata.ts`

---

## Bug 2: MiniMax M2.7 reasoning field not handled

### Symptom
First message hangs (orange → red spinner). API responds correctly when tested with plain `curl`, but OpenClaude never surfaces the response.

### Root Cause
MiniMax M2.7 returns chain-of-thought in a field named `reasoning` (not `reasoning_content` used by DeepSeek/GLM). The shim only handled `reasoning_content`, so MiniMax responses appeared to have no content and the stream stalled.

In streaming chunks:
```json
{ "delta": { "content": "", "reasoning": "The user wants..." } }
```

In non-streaming responses:
```json
{ "message": { "content": "Hi!", "reasoning": "...", "reasoning_details": [...] } }
```

### Fix — Streaming path (`openaiShim.ts`)

Add `reasoning` to the delta type and handle it alongside `reasoning_content`:

```typescript
// Type definition (~line 847)
reasoning_content?: string | null
reasoning?: string | null   // ADD

// Streaming handler (~line 1059)
if (
  (delta.reasoning_content != null && delta.reasoning_content !== '') ||
  (delta.reasoning != null && delta.reasoning !== '')
) {
  const reasoningDelta = delta.reasoning_content ?? delta.reasoning ?? ''
  // ... emit thinking_delta with reasoningDelta
}
```

### Fix — Non-streaming path (`openaiShim.ts`)

```typescript
// Type definition (~line 2165)
reasoning_content?: string | null
reasoning?: string | null   // ADD

// Response handler (~line 2191)
const reasoningText = choice?.message?.reasoning_content ?? choice?.message?.reasoning
```

**File changed:** `src/services/api/openaiShim.ts`

---

## Bug 3: Stream never closes for providers that send `finish_reason: null`

### Symptom
With MiniMax M2.7 via OpenRouter (Fireworks provider), the model sends all content chunks with `finish_reason: null` and closes the SSE stream with `[DONE]`. OpenClaude never emits `content_block_stop` or `message_delta`, so the Anthropic SDK stream handler stalls waiting for a close signal that never arrives.

### Root Cause
The shim only closes open content/thinking blocks inside the `if (choice.finish_reason && !hasProcessedFinishReason)` block. When `finish_reason` is always `null`, this block never runs.

### Fix
After the SSE stream reader loop ends (post-`finally`), emit close events for any blocks that are still open:

```typescript
// After finally { reader.releaseLock() }

// Close any blocks left open when finish_reason never fired
if (hasEmittedThinkingStart && !hasClosedThinking) {
  yield { type: 'content_block_stop', index: contentBlockIndex }
  contentBlockIndex++
  hasClosedThinking = true
}
if (hasEmittedContentStart) {
  yield* closeActiveContentBlock()
}
if (lastStopReason === null && (hasEmittedContentStart || hasEmittedThinkingStart)) {
  yield {
    type: 'message_delta',
    delta: { stop_reason: 'end_turn', stop_sequence: null },
  }
}
```

**File changed:** `src/services/api/openaiShim.ts`

---

## Bug 4: Multi-turn reasoning context lost (MiniMax M2.7)

### Symptom
First message works. Follow-up messages cause the model to loop, output garbage, or go silent. Only affects reasoning models.

### Root Cause
MiniMax M2.7 uses **interleaved thinking** — it requires the full previous reasoning chain to be echoed back in the assistant message history on every subsequent turn. The shim's `convertMessages()` function strips thinking blocks from history by default. Without the reasoning context, the model loses its "bridge" between turns and breaks.

This is gated by `preserveReasoningContent` in `shimConfig`, which was only enabled for DeepSeek and Kimi/Moonshot — not MiniMax.

### Fix
Add MiniMax to `inferRemoteModelOpenAIShimConfig()` in `runtimeMetadata.ts` with `preserveReasoningContent: true`:

```typescript
if (normalizedModel.includes('minimax')) {
  return {
    preserveReasoningContent: true,
    reasoningContentFallback: '',
    maxTokensField: 'max_tokens',
    removeBodyFields: ['store'],
  }
}
```

**File changed:** `src/integrations/runtimeMetadata.ts`

---

## Bug 5: OpenRouter headers missing (optional but recommended)

### Symptom
Some models on OpenRouter stream unreliably or return bot-detection errors without proper identification headers.

### Fix
Inject `HTTP-Referer` and `X-Title` headers for all requests routed through `openrouter.ai`:

```typescript
// After headers object is built in openaiShim.ts
const baseUrl = request.baseUrl ?? process.env.OPENAI_BASE_URL ?? ''
if (baseUrl.includes('openrouter.ai')) {
  headers['HTTP-Referer'] = 'https://github.com/Gitlawb/openclaude'
  headers['X-Title'] = 'OpenClaude'
}
```

**File changed:** `src/services/api/openaiShim.ts`

---

## Important Note: MiniMax M2.7 Tool Call Limitation

MiniMax M2.7 via OpenRouter **does not support function/tool calling**. When tool schemas are included in the request, the model returns an empty response. Since OpenClaude sends tool schemas on every request (it is a coding agent), MiniMax M2.7 cannot be used as the primary model for agentic tasks.

**For coding/agentic tasks use:** `google/gemini-2.0-flash-001` or `deepseek/deepseek-chat-v3-0324`  
**MiniMax M2.7 is suitable for:** plain chat sessions without tool use

---

## Files Changed

| File | Changes |
|---|---|
| `src/services/api/openaiShim.ts` | Added `reasoning` field support (streaming + non-streaming), stream close fallback, OpenRouter headers |
| `src/integrations/runtimeMetadata.ts` | Added MiniMax and Gemini/Google provider configs |
