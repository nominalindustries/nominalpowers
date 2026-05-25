---
name: nominal-async-cleanup-patterns
description: Use when designing or debugging the cancellation and teardown path of a Nominal Tauri app's background work. Covers the tokio AbortHandle vs spawn_blocking trap, the abort-the-cancellable-and-cascade pattern, try_clone for separating reader and writer file descriptors on shared OS resources, and Drop order for struct fields that hold cleanup chains.
---

# Nominal Async Cleanup Patterns

## Overview

A Nominal Tauri app's backend is almost always a small AppState behind `Arc<Mutex<...>>` plus several long-lived tokio tasks: a reader pumping bytes off a wire, a forwarder dispatching them to Tauri events, a watcher reacting to errors, sometimes a TCP server fanning bytes back out. Daily-use correctness depends on those tasks shutting down cleanly when the operator closes a session, unplugs a cable, or quits the app.

This skill is the cluster of patterns that make that cleanup actually work. They share one root cause: **`tokio::task::AbortHandle::abort()` does not cancel `spawn_blocking` tasks**, and most Nominal apps have at least one blocking task (a serial read, a USB poll, a file scan) wrapped in `spawn_blocking`. Naive cancellation paths look correct, compile cleanly, and leak resources at runtime.

## When this triggers

- Designing the lifecycle of any backend struct that owns tokio task handles plus a sender/receiver chain.
- Debugging a "resource is still locked even after I closed it" report from your human partner (file descriptor held, port busy, socket not released).
- Reviewing a Drop impl that holds an `AbortHandle`.
- Wiring a new background task to an existing AppState collection.

## The landmines

### `spawn_blocking` tasks ignore tokio cancellation

`tokio::task::AbortHandle::abort()` is a no-op against work spawned with `tokio::task::spawn_blocking`. The blocking task runs to completion of its closure regardless of how many times anyone calls `abort()`. This is by design (tokio cannot interrupt arbitrary blocking syscalls) but it is easy to miss when reading code: the `AbortHandle` is real, the call compiles, and at first glance the cleanup looks correct.

If your cleanup path hangs on "close this thing that uses a blocking read loop," look here first.

### Cancel the cancellable, then cascade through dropped channels

The pattern that actually works for a blocking-task + forwarder chain:

1. **Hold the AbortHandle for a task that *is* cancellable** (a regular `tokio::spawn` of an async future), not for the `spawn_blocking` one.
2. **Aborting that cancellable task drops its end of the channel** that connects it to the blocking task.
3. **The blocking task's next send or receive returns an error**, the loop breaks, and the blocking handle drops on the way out.

Concretely, for a reader/forwarder pair: the reader is `spawn_blocking` and owns the `mpsc::Sender` for the data channel. The forwarder is `tokio::spawn(async ...)` and owns the `mpsc::Receiver`. On shutdown, abort the forwarder. The receiver drops. The reader's next `blocking_send` returns `Err`, the loop breaks, the file descriptor is released.

The wrong shape: store the reader's `AbortHandle` and call `abort()` on it. That compiles, looks correct, and leaks the fd every time.

### `try_clone` separates reader and writer fds on shareable OS resources

When a long-running task wants to read from a resource while a command path writes to it, do not share one file descriptor behind an `Arc<Mutex<...>>` if the OS API supports duplicating the handle. `serialport::SerialPort::try_clone`, `TcpStream::try_clone`, `std::fs::File::try_clone` all give you a second handle to the same underlying resource without mutex contention.

The shared-mutex shape works correctly but can produce multi-second latency under load when the reader holds the lock across a blocking read with a non-trivial timeout. The separated-handles shape is bounded only by the OS write path.

Pattern: in your "split this resource into a writer half and a reader-task" helper, call `try_clone` first. If it succeeds, give the writer its own handle and the reader-task the original. If it fails (rare on macOS/Linux for the resources Nominal uses), fall back to the shared-mutex shape with a documented warning. The shared-mutex fallback is correct but slower; do not silently ship the slow path.

### Drop order matters in cleanup-bearing structs

A struct that holds both an `AbortHandle` and the channel ends those tasks are waiting on must declare its fields in the right order, because Rust drops fields in declaration order. If the channel sender drops before the abort handle fires, the receiver may have already observed the close and the abort is redundant; if the abort handle fires before the channel drops, the cancellable task is gone and the dropped channel completes the cascade. In practice both orderings work for the patterns above, but be explicit about it in a comment so the next reader is not guessing.

When in doubt, do the cleanup explicitly in `close_X` rather than relying on `Drop`: take the abort handle, abort it, then drop the rest. `Drop` is a safety net for panic paths and app teardown, not the primary cleanup path.

## Worked example: SuperSerial's port-locked-after-close bug

The original `OpenConnection` for a serial tab held the `AbortHandle` for `nominal_serial`'s `spawn_blocking` read loop. `close_tab` called `abort.abort()` and then `drop(conn)`. Both calls compiled, both calls looked correct, and the OS fd stayed open. After closing a tab, opening a new one on the same path failed: the device was busy.

Diagnosis: `abort.abort()` was a no-op against `spawn_blocking`. The forwarder task (a regular `tokio::spawn`) still held the data-channel receiver. The read loop's `blocking_send` always succeeded, the loop never broke, the fd was never released. Restarting the app worked because process teardown killed everything regardless.

Fix: store the **forwarder's** `AbortHandle` in `OpenConnection.abort`. Aborting the forwarder drops `data_rx`. The next `blocking_send` returns `Err`. The reader exits. The fd is released within one read timeout (~100ms in practice).

The fix is a one-line change at the storage site. The lesson is structural: think about which handle is actually cancellable before stashing one.

## Red flags

| Symptom | What it means |
|---|---|
| `AbortHandle` for a `spawn_blocking` task is stored and called | It does nothing. Hold the handle for a cancellable downstream task instead. |
| A resource stays locked / busy / open after the close command returns | Cleanup chain is not closing. Trace which channel each task waits on. |
| Reader and writer share one file descriptor behind a Mutex on a resource that supports `try_clone` | Latency under load. Separate the handles. |
| Cleanup logic lives only in `Drop`, not in the explicit close path | Drop is best-effort and panic-safe. Explicit close is observable and testable. |
| The "before fix" version of the cancellation path compiles and reads correctly | spawn_blocking abort traps look fine until they leak. Read the actual task spawner. |

## Rationalizations to reject

- "Tokio will figure it out." Tokio cannot interrupt blocking syscalls. The closure runs to completion. Plan the cascade.
- "The Mutex is brief, it cannot cause noticeable latency." It is brief in microseconds, but a reader holding it across a 100ms `set_timeout` read is not brief. Measure with the actual timeout that ships, not a synthetic one.
- "Drop will clean up if something goes wrong." Drop is for panic paths. Primary cleanup goes through the explicit close command so it is observable and testable.
- "Falling back to the shared-mutex path silently is fine." It is correct but not fast. Log the fallback so latency reports can find it.
