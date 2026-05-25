---
name: nominal-tauri-state-pattern
description: Use when designing or reviewing the shared backend state of a Nominal Tauri app. Covers the Arc<Mutex<AppState>> pattern via tauri::State, the lock-inside-the-handler discipline, the HashMap-per-collection structure, no-await-while-holding-the-lock, and the best-effort save helper pattern that keeps persistent shape in sync without blocking command paths.
---

# Nominal Tauri State Pattern

## Overview

A Nominal Tauri app's backend keeps shared mutable state in one struct, behind one mutex, registered once with Tauri at boot. Every `#[tauri::command]` reaches in via `tauri::State`, locks briefly, mutates or reads, and releases. Long-running work (read loops, TCP servers, watchers) spawns onto tokio and reports back via Tauri events rather than holding the lock. This shape recurs across SuperLaser, SuperEntropy, Galactic, Nibble, SuperSerial, and works because it is simple, auditable, and the Rust compiler enforces the borrowing rules at every site that touches it.

This skill is the convention set. It is not the only way to structure Tauri state, it is the way Nominal apps converge on.

## When this triggers

- Designing a new Tauri app's `state.rs` or extending an existing AppState with a new collection.
- Reviewing a command that holds a lock across an `.await`.
- Adding a new background task that needs to read or write AppState from outside the command handlers.
- Onboarding a subagent dispatch that touches state; paste the relevant section into the brief.

## The pattern

```rust
// state.rs
pub struct AppState {
    pub tabs: HashMap<TabId, Tab>,
    pub active_tab: Option<TabId>,
    pub snippets_cache: Vec<Snippet>,
    pub db: Option<sqlx::SqlitePool>,
}

// lib.rs, setup hook
let state = Arc::new(Mutex::new(AppState::default()));
app.manage(state);

// commands.rs
#[tauri::command]
pub async fn list_tabs(
    state: State<'_, Arc<Mutex<AppState>>>,
) -> Result<Vec<TabSummary>, String> {
    let guard = state.lock().await;
    Ok(guard.tabs.values().map(Tab::summary).collect())
}
```

The pieces, with their reasons:

- **`Arc<Mutex<AppState>>`** so the same state is reachable from command handlers, spawned tasks, and event-driven watchers without each carrying its own copy. `Arc` is cheap to clone, `Mutex` serializes the mutations.
- **`tokio::sync::Mutex`, not `std::sync::Mutex`.** Command handlers are `async`. `std::sync::Mutex::lock()` does not yield, which is fine in short syscall windows but a hazard if you `.await` inside the guard. `tokio::sync::Mutex::lock()` returns a future; locking is itself a cancellation point. Use tokio's Mutex by default and you do not have to reason about which kind of lock is in scope.
- **`tauri::State<'_, Arc<Mutex<AppState>>>`** as the command signature. Tauri injects the managed state.
- **`AppState::default()` registered once** in `setup` via `app.manage`. Every command sees the same one.

## Lock inside the handler, not at the boundary

Commands lock the state inside the function body, not in a wrapper or middleware. The lock scope is visible in the function, the release point is the closing brace, the borrow checker enforces no-double-lock. This pays off when a future maintainer reads any one command and can see exactly when the state is held without chasing decorators or registration helpers.

For commands that read several things or do conditional work, **scope the lock tight**:

```rust
#[tauri::command]
pub async fn create_tab(
    app: AppHandle,
    state: State<'_, Arc<Mutex<AppState>>>,
    port_path: String,
    config: SerialConfig,
) -> Result<TabSummary, String> {
    // 1. Lock briefly to read the count for default-color picking.
    let next_seq = {
        let guard = state.lock().await;
        guard.tabs.len()
    };

    // 2. Do the slow / fallible thing OUTSIDE the lock.
    let connection = tabs::open_connection(...)?;

    // 3. Lock again to insert.
    let tab = Tab { ..., connection: Some(connection) };
    let summary = tab.summary();
    {
        let mut guard = state.lock().await;
        guard.tabs.insert(tab.id, tab);
    }
    Ok(summary)
}
```

Three short critical sections beats one long one. If a serial port `open()` syscall blocks for 200ms, you do not want every other command queued behind it.

## No await while holding the lock for an unbounded time

Inside `let guard = state.lock().await;` and `drop(guard);`, do not `await` on anything that can hang: network IO, file IO with no timeout, long-running computations, channel sends to a slow consumer. Every other lock attempt is queued behind your guard for as long as that await takes.

Cheap awaits (a brief `tokio::time::sleep`, an in-process channel `.send` on a bounded channel with capacity, an already-resolved future) are fine. Anything that touches the OS or another process should happen before the lock or after.

This rule is why the helpful pattern is **snapshot under the lock, work outside the lock, lock again to commit**. The snapshot is usually a clone of a small struct, the work is the slow part, the commit is the mutation.

## HashMap-per-collection structure

Multi-thing state (tabs, snippets, bookmarks, flasher targets) goes into a `HashMap<Id, Thing>` field on `AppState`. The id type is meaningful (`type TabId = Uuid;`) and is what gets serialized to the renderer. Iteration order is unstable; commands that need a stable order sort on a known field (`created_at`, `sort_order`) at the boundary, not in AppState.

When a renderer holds onto an id and asks the backend "do X to tab Y", the command's first move is:

```rust
let tab = guard.tabs.get_mut(&tab_id)
    .ok_or_else(|| format!("no tab with id {tab_id}"))?;
```

That string error is what `Result<T, String>` carries across to the renderer per `nominal-tauri-ipc-shape`. Friendly enough to log, predictable enough to ignore.

## Background tasks reach in via a state clone

A spawned task that needs AppState gets an `Arc<Mutex<AppState>>` cloned at spawn time. It cannot use `tauri::State` because that's a command-scoped accessor. The pattern:

```rust
let state_for_task = state.inner().clone();
tokio::spawn(async move {
    let guard = state_for_task.lock().await;
    // do the thing
});
```

In a Nominal app this is how byte-forwarders, error watchers, and TCP server tasks reach in to mutate their tab's record on a state change. The lock-inside-handler discipline applies here too, including no-await-while-holding.

## save_X helpers for best-effort persistence

When state mutations need to be mirrored to SQLite, do not put the DB writes inline in the command body. They are best-effort (a DB hiccup should not fail tab creation) and they need their own lock acquisition (after the primary mutation released its lock). Factor the persistence into a helper that takes the state handle and the id of the thing to save:

```rust
async fn save_tab(state: &State<'_, Arc<Mutex<AppState>>>, tab_id: TabId) {
    let Some(pool) = maybe_db(state).await else { return };
    let persisted = {
        let guard = state.lock().await;
        let Some(tab) = guard.tabs.get(&tab_id) else { return };
        PersistedTab::from(tab)
    };
    if let Err(e) = tab_persistence::persist_tab(&pool, &persisted).await {
        log::warn!("persist tab {tab_id} failed (non-fatal): {e}");
    }
}
```

Commands that mutate persistent shape call `save_tab(&state, id).await` after the primary mutation. The error is logged, not returned. The renderer sees the mutation succeed; the DB catches up; if the DB write actually failed the next mutation will overwrite the stale row anyway. See `nominal-persistent-collections` for the full pattern.

## Red flags

| Symptom | What it means |
|---|---|
| `std::sync::Mutex<AppState>` in a Tauri command | The handler is async. Use `tokio::sync::Mutex` so locking is a proper await point. |
| Lock acquired at the start of the function, awaiting on network IO before release | Every other command is queued behind this. Snapshot, release, work, re-lock. |
| Lock in a wrapper or middleware, not in the command body | Lock scope is invisible at the call site. Lock inside the function. |
| State mutations and DB persistence interleaved in the same critical section | Persistence is best-effort and should not extend the lock. Factor a save_X helper. |
| Background task constructs its own `AppState` rather than receiving the shared one | The state is now divergent. Pass the Arc<Mutex<AppState>> through to the spawn. |
| Iteration order of a HashMap relied on as stable | HashMaps in Rust have a randomized order per process. Sort at the boundary on a known field. |
| Inline DB error returned from a command and surfaced as a user-facing failure | A best-effort persist should log and continue. Return the user-relevant error, not the bookkeeping one. |

## Rationalizations to reject

- "The std Mutex is faster." It is, by nanoseconds. The cost of getting it wrong (`.await` inside the guard) is hours of debugging. Use tokio's by default.
- "Locking in middleware is more DRY." It hides the lock scope. The command body is where the borrow checker can see and reason about it.
- "Inline persistence is less code." It also extends the lock and entangles user-visible errors with bookkeeping ones. Save helpers earn their lines.
- "A background task can keep its own state if I get the events right." Two sources of truth get out of sync. One AppState, many readers, every mutation goes through it.
