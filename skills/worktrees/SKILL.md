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
3. **Do the work in the worktree.** All edits for the task happen here, never on the baseline branch.
4. **Verify before returning.** Validators green again before the dispatch returns. See `verification-before-completion`.
5. **Integrate, then tear down.** Once the work is reviewed and integrated, remove the worktree and its branch as part of `finishing-a-branch`. Leftover worktrees accumulate and confuse the next session.

## Red flags

| Symptom | What it means |
|---|---|
| Work started without checking the baseline was green | You cannot now distinguish new breakage from old. Always baseline first. |
| Dispatched work happened on the main branch | No isolation. A bad dispatch corrupts everything. |
| Two parallel dispatches shared one worktree | They will collide. One worktree per dispatch. |
| Old worktrees are still lying around | Tear them down at finish. They confuse later sessions. |
| The baseline was red and work proceeded anyway | Fix or acknowledge the baseline first, or every result is ambiguous. |

## Rationalizations to reject

- "The baseline is surely fine, I will skip the check." If you skip it and something is red later, you cannot tell whose fault it is. The check costs seconds.
- "A worktree is overkill for this." For anything dispatched, it is not. Isolation is what makes dispatch safe.
- "I will clean up the worktrees later." Later is how they accumulate. Tear down at finish.
