---
name: lead-thread-workflow
description: Use when running engineering work on a Nominal project that is large enough to need orchestration - a feature, a milestone, a build with several parts. Establishes how the lead thread plans, dispatches subagents, integrates their work, and verifies it.
---

# Lead Thread Workflow

## Overview

A Nominal project of any size is built with one lead thread orchestrating dispatched subagents. The lead thread is the lead developer: it holds the architecture and the plan, it dispatches scoped work, and it integrates and verifies what comes back. It does not personally do every task. This is the workflow that made past builds fast.

## When this triggers

Fires when engineering work is large enough to need orchestration: a feature with multiple parts, a milestone, a build that decomposes into separable tasks. A genuinely tiny one-file change does not need the full workflow, just do it.

## The workflow

1. **The lead thread holds the architecture.** Before any dispatch, the lead thread has the design and the constraints clear. Your human partner brings architecture and constraints, the lead thread carries them through the build.
2. **Plan into dispatchable tasks.** Decompose the work into small, scoped, independently executable tasks. See `writing-plans`. A task that cannot be handed off cleanly is not yet planned.
3. **Set up isolation.** Work happens in worktrees so a dispatch cannot corrupt the baseline. See `worktrees`. Confirm a clean validator baseline before starting.
4. **Dispatch.** Hand each task to a subagent with everything it needs: the goal, the constraints, the relevant files, the definition of done. See `dispatching-subagents`. Independent tasks can go out in parallel, see `parallel-dispatch`.
5. **Integrate and verify, do not rubber-stamp.** When a dispatch returns, the lead thread reviews it: did it meet the spec, is the code sound, do the external validators pass. A returned dispatch is a proposal, not a finished fact. See `code-review` and `verification-before-completion`.
6. **Keep your human partner oriented.** The lead thread is also the external memory. Track what is dispatched, what is integrated, what is open. Your human partner should be able to ask "where are we" and get a straight answer without reconstructing it.
7. **Close cleanly.** When the work is done and verified, finish the branch deliberately. See `finishing-a-branch`.

## Red flags

| Symptom | What it means |
|---|---|
| The lead thread did all the work itself | The model is orchestration. Dispatch the separable tasks. |
| A dispatch went out underspecified | The subagent will guess. Give it the full task. |
| A returned dispatch was merged without review | Returned work is a proposal. Integrate and verify. |
| Work happened on the baseline with no worktree | One bad dispatch can now corrupt everything. Isolate. |
| Your human partner asked "where are we" and you had to reconstruct it | The lead thread is the external memory. Track state continuously. |
| Validators were not green before work started | You cannot tell new breakage from old. Baseline first. |

## Rationalizations to reject

- "This task is small, I will just do it in the lead thread." Small separable tasks are exactly what dispatch is for. Doing them inline bloats the lead thread's context.
- "The subagent is competent, I do not need to review the result." Competence is not verification. Review every returned dispatch.
- "Setting up a worktree is overhead." It is the overhead that makes parallel and isolated work safe. It pays for itself on the first bad dispatch.
