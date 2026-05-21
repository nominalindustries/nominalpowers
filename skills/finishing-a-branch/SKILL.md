---
name: finishing-a-branch
description: Use when a piece of engineering work is verified and the branch or worktree needs to be closed out. Covers the deliberate merge, PR, or discard decision and the cleanup that follows, so work ends cleanly instead of trailing loose ends.
---

# Finishing a Branch

## Overview

Work that is verified still has to be closed out, and closing out is a decision, not a reflex. The branch can be merged, turned into a PR, kept for now, or discarded. Each is a real option. And whatever is decided, the worktree gets cleaned up. Finishing is the transition that, skipped, leaves a repo full of stale branches and orphaned worktrees that confuse the next session.

## When this triggers

Fires when a piece of work is verified complete and the branch or worktree it lives on needs resolving.

## How to finish

1. **Verify first.** Do not finish unverified work. The validators are green, the goal is confirmed, see `verification-before-completion`. Finishing is the step after verification, never instead of it.
2. **Decide the disposition, deliberately.** The options:
   - **Merge** - integrate into the target branch. For work that is done and wanted.
   - **PR** - open a pull request for review or for a record, where the project's flow expects one.
   - **Keep** - leave the branch as-is for now, when the work is paused rather than finished.
   - **Discard** - delete the branch, when the work was a dead end or an experiment that answered its question. Discarding is a legitimate, useful outcome, not a failure.
   This is your human partner's call to confirm. Surface the options, do not assume merge.
3. **Mind the action class.** Merging, opening a PR, and deleting a branch are consequential git actions. Confirm with your human partner before taking them, do not finish a branch unilaterally.
4. **Clean up the worktree.** Once disposition is decided, remove the worktree for the task, see `worktrees`. Remove the branch too if it was merged or discarded. Leftover worktrees and stale branches accumulate and confuse later work.
5. **Capture loose ends.** If finishing surfaced follow-up work, a deferred improvement, a noticed bug, record it where it will be found, do not let it live only in the thread. See spicypowers' `transitions`.

## Red flags

| Symptom | What it means |
|---|---|
| A branch was merged without verification | Finishing is post-verification. Verify first. |
| Merge happened without confirming with your human partner | Consequential git action. Confirm before finishing. |
| The worktree was left behind after finishing | Stale worktrees accumulate. Clean up. |
| "Discard" was never considered, merge was assumed | Discard is a real option. Surface all of them. |
| Follow-up work surfaced and was left in the thread only | It will be lost. Record it where it is findable. |

## Rationalizations to reject

- "The work is obviously good, I will just merge it." Merge is consequential and is your human partner's call. Confirm.
- "I will clean up the worktree later." Later is how worktrees pile up. Clean up as part of finishing.
- "Discarding the branch wastes the work." A dead end that answered its question did its job. Discard is not waste.
