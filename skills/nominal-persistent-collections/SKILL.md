---
name: nominal-persistent-collections
description: Use when designing the persistence layer for a Nominal app's collection of dynamic things (tabs, sessions, bookmarks, flasher targets, snippets). Covers persisting static shape only, restoring as a quiescent state, the boot-time race fix via a restored event, the best-effort save helper, and forgetting on close.
---

# Nominal Persistent Collections

## Overview

A useful Nominal app has collections that the operator builds up over time: the tabs they had open last session, the snippets they pinned, the bookmarks they saved, the flasher targets they configured. When they relaunch the app, those things should come back. When they close one explicitly, it should stay gone.

The naive shape, "serialize the live struct including its runtime handles, deserialize on boot, resume," does not work for any of these. A SerialPort handle, an open SqlitePool, a TcpListener, a BufWriter on a log file, none of these are serializable, and silently re-engaging them on boot has real-world side effects (DTR toggles, network round-trips, file truncation) the operator did not ask for.

This skill is the pattern that actually works: persist the **static shape**, restore as a **quiescent state**, and require an explicit operator action to re-engage. It is the same shape across every persistent collection in a Nominal app, so once you have written it once you copy it.

## When this triggers

- Designing a new persistent collection (tabs, bookmarks, saved sessions, etc.).
- Reviewing a feature that "persists the open thing" without thinking about what re-opening means.
- Debugging a "my saved thing came back but acts weird" report (usually because runtime state was implicitly assumed).
- Onboarding a subagent dispatch that adds persistence; paste the relevant section into the brief.

## The pattern

### Persist the static shape only

A struct that combines persistent shape and runtime handles is two structs glued together. Split them.

```rust
// Live record in AppState. Holds the runtime handles.
pub struct Tab {
    pub id: TabId,
    pub name: String,
    pub color: String,
    pub port_path: String,
    pub config: SerialConfig,
    pub created_at: DateTime<Utc>,
    pub state: TabState,
    pub last_error: Option<String>,
    pub connection: Option<OpenConnection>,   // not persisted
    pub log: Option<LogState>,                // not persisted
}

// What goes to disk. Same identity, just the static parts.
#[derive(Serialize, Deserialize)]
pub struct PersistedTab {
    pub id: TabId,
    pub name: String,
    pub color: String,
    pub port_path: String,
    pub config: SerialConfig,
    pub created_at: DateTime<Utc>,
}
```

Runtime fields (`connection`, `log`, anything holding a file descriptor / socket / abort handle / channel sender) **never** appear in `PersistedTab`. Including them is either impossible (not Serialize) or wrong (a fd from yesterday's process is meaningless today).

### Schema: one column per atomic field, JSON blob for nested structs

A SQLite table that mirrors `PersistedTab`:

```sql
CREATE TABLE tabs (
    id          TEXT PRIMARY KEY,    -- UUIDv4 string
    name        TEXT NOT NULL,
    color       TEXT NOT NULL,       -- "#RRGGBB"
    port_path   TEXT NOT NULL,
    config_json TEXT NOT NULL,       -- serde_json(SerialConfig)
    created_at  INTEGER NOT NULL     -- unix epoch seconds
);
```

Atomic fields get their own columns so a `sqlite3` shell can grep them. Nested structs go in as JSON; the schema does not have to change when the struct adds a field, and the deserialize either parses or skips the row with a logged warning.

### Restore as a quiescent state

On boot, after the SQLite pool initializes, load every persisted row and materialize each into a live `Tab` with the runtime handles set to `None` and the state set to the safe quiescent variant:

```rust
let restored = tab_persistence::load_all(&pool).await?;
let mut guard = state.lock().await;
for ptab in restored {
    guard.tabs.insert(ptab.id, Tab {
        id: ptab.id,
        name: ptab.name,
        color: ptab.color,
        port_path: ptab.port_path,
        config: ptab.config,
        created_at: ptab.created_at,
        state: TabState::Disconnected,    // quiescent
        last_error: None,
        connection: None,
        log: None,
    });
}
```

The renderer sees the tabs come back; the user clicks Reconnect to actually open the port. **Never auto-engage.** Auto-opening every persisted thing on boot is how a serial app silently toggles every DTR line the operator ever talked to, how a chat app pings every channel they ever joined, how an SSH manager auto-redials every host. The user did not ask. Make them ask.

### Boot-time race: emit a restored event

The renderer mounts and calls `list_tabs` to hydrate. The backend's DB-init is on a tokio spawn so the renderer can mount before SQLite is ready. The race:

- If `list_tabs` runs **before** init finishes: returns empty, renderer renders empty state.
- If `list_tabs` runs **after** init finishes: returns the restored set, renderer renders correctly.

Without coordination, the empty-state branch sticks even though the tabs were eventually restored.

**Fix: emit an event after restore.**

```rust
// After populating AppState.tabs from PersistedTab rows:
let summaries: Vec<_> = guard.tabs.values().map(Tab::summary).collect();
drop(guard);
if !summaries.is_empty() {
    app.emit("serial://tabs-restored", &summaries).ok();
}
```

The renderer subscribes on mount and **merges** the event payload into local state:

```typescript
listen<TabSummary[]>("serial://tabs-restored", (event) => {
  setTabs((prev) => {
    const restoredIds = new Set(event.payload.map((t) => t.id));
    const preserved = prev.filter((t) => !restoredIds.has(t.id));
    return [...event.payload, ...preserved];
  });
});
```

The event-merge is race-safe: it converges whether `list_tabs` returned empty (event populates) or full (event re-syncs). It also tolerates a tab the operator created during the boot window before the restore landed (the `preserved` filter keeps it).

### Save on mutation, best-effort

Every command that mutates persistent shape (`create_tab`, `close_tab`, `set_tab_config`, `set_tab_metadata`) fires through to the DB at the end. The save is **best-effort**: a DB write failure logs and is swallowed, the command still returns success to the renderer. See `nominal-tauri-state-pattern` for the helper shape.

Disconnect / reconnect / temporary state changes (connection field flipping, last_error appearing and clearing) do **not** trigger a save. They are runtime state, not persistent shape.

### Forget on close

When the operator explicitly closes a tab, two things must happen:

1. The runtime handles drop (the read task aborts, the connection closes; see `nominal-async-cleanup-patterns`).
2. The persisted row is deleted so the next launch does not resurrect the tab.

`forget_tab(pool, id)` deletes the row. Same best-effort policy: log and continue on error. The next boot may resurrect a closed-but-not-forgotten tab; treat it as a cosmetic bug to fix, not a data integrity issue.

## Schema migrations across versions

When a persisted struct gains a field, the safe path is:

1. **Add the field as Optional in the Rust struct**, populated via `#[serde(default)]`.
2. **Old rows deserialize cleanly**, the new field is `None`.
3. **New writes set the field**; eventually every row in the DB has it.
4. **Promote to required** only after enough versions have passed that you are willing to invalidate the few stragglers.

When a persisted struct loses a field, `#[serde(default)]` on the consumer side ignores the extra JSON. No schema migration needed.

When a column needs renaming or a JSON shape needs restructuring, write an explicit SQL migration in `migrations/` per `nominal-tauri-scaffold`. The `sqlx migrate!` macro runs them in order at boot.

## Red flags

| Symptom | What it means |
|---|---|
| The persisted struct includes a `JoinHandle`, `AbortHandle`, file descriptor, socket, or `SqlitePool` | These are runtime state. Split into a static-shape persisted type and a live type. |
| Boot auto-reconnects / auto-opens every restored thing | Side effects without consent. Restore as quiescent, make the operator engage. |
| Renderer never sees restored items because `list_tabs` ran before DB init | Add a `*-restored` event and merge in the renderer. |
| A DB write error fails the user-facing command | Persistence is best-effort. Log the DB error, return command success. |
| Closed-then-restored items keep coming back | Missing the `forget_X` step on close. Delete the row when the operator closes. |
| Schema migration that drops or renames a column with no SQL migration | Old rows will not deserialize. Either keep the column (use `#[serde(default)]`) or write the migration. |
| Persistent shape and runtime handles share one struct | They are two concerns glued together. Split them; the split pays for itself on the first migration. |

## Rationalizations to reject

- "We can just serialize the whole struct." Runtime handles cannot serialize and re-engaging them has real-world side effects. Static shape only.
- "Auto-reconnect on boot is convenient." It is also surprising, side-effecting, and not what the operator asked for. Make them engage explicitly.
- "If `list_tabs` is empty on first call, the renderer can just retry." That is polling around a race. The event-merge converges in one round trip.
- "DB writes are fast, we can put them in the critical path." They are usually fast and occasionally slow. Best-effort + helper out of band keeps the command surface predictable.
- "We will add the restored event later, the empty initial render is fine for now." It is not fine, it is a confusing first-launch experience. Wire the event from the first persistent collection onward.
