---
name: nominal-tauri-ipc-shape
description: Use when designing or reviewing a Nominal Tauri app's IPC surface, the Tauri commands and events that cross the Rust↔TypeScript boundary. Covers hand-written type mirrors, snake_case-via-serde conventions, the single-channel-with-id-in-payload event pattern, Result<T, String> at the boundary, and the verb conventions for commands.
---

# Nominal Tauri IPC Shape

## Overview

In a Nominal Tauri app, the wire format between Rust and TypeScript is the contract. Two halves of every feature, the `#[tauri::command]` and the `invoke<T>(...)` wrapper, must agree on field names, casing, error shape, and lifecycle, or features fail silently at runtime in ways the compiler cannot catch. Nominal apps converge on one boundary shape and follow it consistently so a new command takes ten minutes to wire and a regression is obvious on read.

This skill is the convention set. None of it is invented per app, none of it is up for re-litigation per feature. When a new command or event is added, it matches the shape below.

## When this triggers

- Designing a new `#[tauri::command]` or its paired `invoke` wrapper.
- Adding a new Tauri event channel or extending an existing event payload.
- Reviewing PR diffs touching `src-tauri/src/commands.rs` or `src/app/lib/api.ts`.
- Onboarding a subagent dispatch that adds backend surface area, the contract goes in the prompt verbatim, see `dispatching-subagents`.

## Hand-written type mirrors, no codegen

Every type that crosses the boundary has two definitions: the Rust struct in `src-tauri/src/state.rs` (or wherever its domain lives) and the TypeScript `interface` in `src/app/lib/api.ts`. The TS name matches the Rust name **verbatim** (`TabSummary` on both sides), field names match verbatim, and the TS version sits in the same module as the wrapper functions that consume it.

We do not codegen these. Codegen pipelines introduce build-time coupling and surprise breaks that are not worth the marginal savings for a small set of types. Writing both halves by hand keeps the boundary auditable: grep one name and you find both ends.

The discipline is grep-friendliness. If a Rust struct gets renamed, a search for the old name should find the TS mirror at the same time. Pick one canonical name, use it on both sides.

## Snake_case on the wire via serde

Rust enums use `#[serde(rename_all = "snake_case")]`. Rust struct field names are already snake_case and serialize as-is. The TypeScript mirror is therefore also snake_case at the field level:

```typescript
export interface TabSummary {
  id: TabId;
  port_path: string;       // not portPath
  config: SerialConfig;
  state: TabState;         // "connected" | "disconnected" | "error"
  created_at: string;      // RFC3339 UTC
}
```

This makes JSON inspectable end-to-end (devtools network panel, console logs, session-log dumps) without case-translation guessing. Tauri's `invoke` does perform camelCase→snake_case translation on **command argument keys** (the second arg to `invoke`), so the TS wrappers take camelCase parameter names and Tauri shapes them on the way through. The structs themselves stay snake_case on both sides.

## Result<T, String> at the boundary

Every command returns `Result<T, String>`. The `T` is the success payload (often a structured type); the `Err(String)` is a human-readable message the renderer can either display in a toast or pipe to `console.error`. The boundary does not carry typed Rust error enums; serializing them across is more overhead than it is worth and the renderer cannot dispatch on them usefully.

This means the renderer's wrapper function returns `Promise<T>` and rejects with the error string on `Err`. The wrapper does no special handling, the call site decides whether to surface, retry, or swallow.

When a backend error has structure the renderer needs (validation errors with field references, multiple sub-errors), use `Result<T, ErrorDto>` where `ErrorDto` is a small struct that serializes cleanly. Reserve this for cases where the structure earns its keep, the default is `Result<T, String>`.

## Single channel per event-kind, id in the payload

When a backend event applies per-tab, per-session, or per-anything, **do not** create one Tauri event channel per id (`serial://data/<tab_id>`). **Do** create one channel per event-kind and put the id in the payload:

```rust
pub const EVENT_SERIAL_DATA: &str = "serial://data";

#[derive(Serialize)]
pub struct SerialDataEvent<'a> {
    pub tab_id: TabId,
    pub bytes: &'a [u8],
}
```

The frontend subscribes once per channel and filters by id in JS:

```typescript
listen<SerialDataEvent>(EVENT_SERIAL_DATA, (event) => {
  if (event.payload.tab_id !== myTabId) return;
  term.write(new Uint8Array(event.payload.bytes));
});
```

Why this pattern beats channel-per-id:

- N subscriptions on a noisy renderer becomes thousands of listeners on a busy app. Tauri's listener overhead is small but not free.
- Cleanup on tab close is one `unlistenFn()`, not a per-tab cleanup table.
- A new pane that wants the same stream subscribes the same way as the existing ones, no channel-name plumbing.

The renderer naturally pays a small "filter by id" cost on every event. For Nominal serial volumes (single-port chunks at 921600 baud max, a couple of MB/s), this is invisible. For higher rates, premature.

The TS-side event constants and payload types live in `api.ts` alongside the command wrappers, so a consumer imports one module and gets the entire boundary.

## Command verb conventions

Commands are snake_case Rust functions, named for the verb plus the noun they act on. Use the following verbs by convention so the API surface is scannable:

- `list_<things>` returns `Vec<ThingSummary>`. No pagination unless the collection is unbounded; Nominal apps are operator-tools, not directories.
- `create_<thing>(...) -> Result<ThingSummary, String>` constructs and registers; on error, leaves no orphan.
- `close_<thing>` removes (cleans up runtime handles, drops from state, persists the removal).
- `disconnect_<thing>` retires runtime handles but keeps the persistent shape, so a reconnect command can re-engage.
- `reconnect_<thing>` re-engages a previously-disconnected thing using its stored shape.
- `set_<thing>_<aspect>` updates one aspect (`set_tab_metadata` renames/recolors, `set_tab_config` updates port path + serial config). One verb per aspect avoids 12-argument update commands.
- `write_<bytes|string>(...)` per-tab IO. The byte form is for raw frames, the string form takes a line-ending enum.

The TypeScript wrapper is camelCase (`listTabs`, `createTab`, `setTabConfig`). The function calls `invoke("list_tabs", ...)` with the Rust name as the literal string. The literal lives in exactly one place per command.

## Verifying the contract is honored

The compiler catches drift on the Rust side but cannot reach across to TS. The validators that find boundary drift in practice:

- `tsc --noEmit` catches missing or misnamed TS fields when the wrapper destructures the response.
- `cargo check` catches missing or misnamed Rust struct fields.
- The first manual smoke test catches casing or shape drift that survives both above (a successful invoke that returns `null` because TS expected `portPath` and Rust sent `port_path`).

The boundary is the highest-value spot for a smoke test. After wiring a new command, do one round trip through the dev build before moving on.

## Red flags

| Symptom | What it means |
|---|---|
| Codegen tool reading Rust types and emitting TS | Discard. Hand-written mirrors are the Nominal convention; the maintenance saved is not worth the build-time coupling. |
| Tauri command returning `Result<T, MyEnum>` | The renderer cannot dispatch on Rust enum variants usefully. Use `Result<T, String>` unless the structure is genuinely needed. |
| Per-id event channel (`serial://data/<id>`) | The frontend will accumulate listeners. Use one channel + id in the payload. |
| TS interface field is camelCase | The wire is snake_case. Match it on the TS side. |
| Backend invents a casing rule per command | Pick one shape (snake_case fields, snake_case command names, camelCase arg keys to `invoke`). Drift kills grep-friendliness. |
| New command added without its TS wrapper in the same commit | The boundary is two halves of one feature. Always add both. |
| TS wrapper hardcodes Rust struct field assumptions in multiple places | Define the interface once, import it. One canonical name per type. |
| Tauri invoke fails silently with `null` | Casing or shape drift between Rust struct and TS interface. The compiler does not see this; smoke-test the round trip. |

## Rationalizations to reject

- "Codegen would save typing." It would save a small amount of typing and introduce a build-step on a fast-moving boundary. Type both halves; the maintenance is bounded and the auditability is huge.
- "Channel-per-id is cleaner because each subscriber is exact." It scales worse, makes cleanup messy, and obfuscates the data flow. One channel + filter is the Nominal default.
- "Typed Rust errors across the boundary would let the renderer handle them precisely." The renderer almost never needs that precision. `Result<T, String>` is the default; structured errors are an exception that has to earn its keep.
- "I will fix the casing on review." The compiler does not catch boundary casing drift. Match snake_case on both sides at write time.
