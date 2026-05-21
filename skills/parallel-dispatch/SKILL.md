---
name: parallel-dispatch
description: Use when the lead thread has several independent tasks that could run at the same time. Covers how to dispatch subagents in parallel without their work colliding, and how to integrate parallel results.
---

# Parallel Dispatch

## Overview

When several planned tasks do not depend on each other, the lead thread can dispatch them to subagents at the same time. This is where the workflow gets fast. The risk is collision: two parallel dispatches touching the same files, or making incompatible assumptions, produce a merge mess that costs more than the parallelism saved. Parallel dispatch is worth it only when the tasks are genuinely independent.

## When this triggers

Fires when the lead thread is holding multiple tasks and is deciding whether to run them concurrently.

## How to dispatch in parallel

1. **Verify genuine independence first.** Two tasks are safe to parallelize only if they do not touch the same files and do not depend on each other's output. If task B needs task A's result, they are sequential, not parallel. Check before dispatching, not after.
2. **Isolate each dispatch.** Each parallel subagent works in its own worktree. See `worktrees`. Shared workspace plus parallel work equals corruption.
3. **Partition the surface.** Assign each dispatch a clear, non-overlapping set of files. If two tasks genuinely must share a file, that is a dependency, sequence them or merge them into one dispatch.
4. **Brief each fully and independently.** Every parallel dispatch gets a complete briefing on its own, see `dispatching-subagents`. A parallel subagent cannot see its siblings' work.
5. **Integrate one at a time, re-verifying.** Bring parallel results back in sequence. After each integration, run the validators again before integrating the next. Two results that each passed in isolation can still conflict once combined.
6. **Sequence the dependent remainder.** Tasks that did not qualify as independent run after, in dependency order. Do not force parallelism that the dependency graph does not allow.

## Red flags

| Symptom | What it means |
|---|---|
| Two parallel dispatches edited the same file | They were not independent. That is a merge conflict you created. |
| A parallel subagent needed another's output | That is a dependency. It should have been sequenced. |
| Parallel work happened in a shared workspace | No isolation. Each dispatch needs its own worktree. |
| All parallel results were merged at once, then validated | Integrate one at a time, re-verify between each. |
| You parallelized to feel fast, not because tasks were independent | False parallelism. The merge cost erases the gain. |

## Rationalizations to reject

- "These tasks are probably independent enough." Probably is not good enough. Verify the file surfaces do not overlap.
- "I will sort out the conflicts at integration." Conflicts at integration are the cost parallel dispatch is supposed to avoid. Prevent them by partitioning.
- "Validating once after all merges is faster." It is faster until two results conflict and you cannot tell which. Re-verify between integrations.
