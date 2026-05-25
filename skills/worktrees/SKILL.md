---
name: worktrees
description: Use when starting a piece of dispatched or isolated engineering work that should not happen directly on the main branch. Covers setting up a git worktree, verifying a clean baseline before touching anything, and tearing down afterward.
---

# Worktrees

## Overview

A git worktree is a separate working directory on its own branch, sharing the same repository. Nominal engineering work happens in worktrees so a dispatch cannot corrupt the baseline and parallel dispatches cannot collide. This is blast-radius isolation applied to the act of writing code, the same `design-for-failure` principle as separating Terraform state per concern.

## When this triggers

Fires when starting dispatched work, parallel work, or any change substantial enough that doing it directly on the main branch is a risk. A trivial one-line fix may not need one, anything a subagent touches does.

## How to use a worktree

1. **Create the worktree on its own branch.** Each isolated task gets its own worktree and branch. Each parallel dispatch gets its own, separate from the others.
2. **Verify a clean baseline before any work.** Run the external validators in the fresh worktree, see `external-validators`. They must be green before a single change. This is non-negotiable: if you do not know the baseline was clean, you cannot tell new breakage from pre-existing breakage, and every later failure becomes ambiguous.
3. **Check main for uncommitted work that the worktree base will not see.** A worktree branches from a specific commit. If the main branch carries uncommitted changes when you dispatch, the subagent's worktree starts without them, and an integration that copies the subagent's files over main will silently overwrite that uncommitted work. Either commit the in-progress changes to main first, or plan to **3-way merge** the subagent's result against main rather than copying. A copy is a cheap, lossy integration tool, it works only when the lead's main matches the worktree's base.
4. **Do the work in the worktree.** All edits for the task happen here, never on the baseline branch.
5. **Verify before returning.** Validators green again before the dispatch returns. See `verification-before-completion`.
6. **Integrate, then tear down.** Once the work is reviewed and integrated, remove the worktree and its branch as part of `finishing-a-branch`. Leftover worktrees accumulate and confuse the next session.

## Watch-out: Nominal path-dep resolution from inside a worktree

A Nominal Tauri app uses path deps to the shared `nominal-sdks-rust` workspace, by convention as `../../nominal-sdks-rust/<crate>` from `src-tauri/Cargo.toml`. That relative path is computed against the app repo's main checkout location. From inside a worktree at `.claude/worktrees/agent-X/src-tauri/`, the same string climbs the wrong number of directories and the path dep fails to resolve. Every validator that touches Cargo (`cargo check`, `cargo clippy`, `cargo test`) then fails for the wrong reason, and a subagent that does not know to expect this will burn its budget on a phantom build error.

The working pattern, as a dispatch instruction: tell the subagent to **temporarily swap the path dep for the absolute path on its machine** (`/Users/<you>/code/.../nominal-sdks-rust/<crate>`) while running the verification step, then **revert before reporting**. The final committed-state Cargo.toml uses the original relative path so the lead's integration into main is clean. This is the difference between a productive worktree subagent and one that stalls trying to figure out what is going wrong, see `nominal-sdk-extraction` for the workspace shape that produces this landmine.

## Red flags

| Symptom | What it means |
|---|---|
| Work started without checking the baseline was green | You cannot now distinguish new breakage from old. Always baseline first. |
| Main carried uncommitted work when a dispatch went out, and integration copied files over | The lead just overwrote uncommitted work on main. Commit first or 3-way merge. |
| Dispatched work happened on the main branch | No isolation. A bad dispatch corrupts everything. |
| Two parallel dispatches shared one worktree | They will collide. One worktree per dispatch. |
| A worktree subagent's `cargo check` fails on "could not find Cargo.toml" for a nominal-sdks-rust crate | Path dep does not resolve from the worktree depth. Brief the subagent to swap to an absolute path during verification and revert. |
| Old worktrees are still lying around | Tear them down at finish. They confuse later sessions. |
| The baseline was red and work proceeded anyway | Fix or acknowledge the baseline first, or every result is ambiguous. |

## Rationalizations to reject

- "The baseline is surely fine, I will skip the check." If you skip it and something is red later, you cannot tell whose fault it is. The check costs seconds.
- "A worktree is overkill for this." For anything dispatched, it is not. Isolation is what makes dispatch safe.
- "I will clean up the worktrees later." Later is how they accumulate. Tear down at finish.
- "Main is probably committed enough." Probably is not good enough. The cost of a `git status` check before dispatching is seconds. The cost of finding a clobbered uncommitted change later is hours.
- "The subagent will figure out the path dep on its own." Sometimes it does, sometimes it stalls on it for ten minutes. Brief the workaround in the dispatch and never find out which it would have been.
