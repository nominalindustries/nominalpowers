---
name: dispatching-subagents
description: Use when the lead thread is handing a scoped task to a subagent. Covers how to brief a dispatch so the subagent can execute without guessing, and the two-stage review applied to the result when it comes back.
---

# Dispatching Subagents

## Overview

A dispatch is one scoped task handed to a subagent. The subagent starts fresh: it knows only what the dispatch tells it. So the quality of a dispatch is set by the briefing, and the safety of it is set by the review when it returns. This skill is both halves.

## When this triggers

Fires when the lead thread is about to hand a task to a subagent, and again when a dispatched task returns for integration.

## Briefing a dispatch

A subagent has no memory of the project. The dispatch must carry everything.

1. **State the goal and the definition of done.** What the task must achieve, and how the subagent will know it is finished. "Done" must be checkable, not vibes.
2. **Give the constraints.** The architecture decisions, the conventions, the patterns this task must respect. The subagent cannot infer Nominal conventions, name them.
3. **Point at the relevant files.** Which files to read, which to change, which to leave alone. Do not make the subagent hunt.
4. **Name the validators.** What must pass: cargo fmt, clippy with warnings denied, tsc, the test suite. The subagent should run them before returning.
5. **Scope it tight.** One task, one dispatch. A dispatch that sprawls is hard to review and hard to isolate. If it is really several tasks, it is several dispatches.
6. **Write for a capable stranger.** The subagent is competent but has no judgement about this project's intent. Be explicit. Ambiguity becomes a guess, and a guess becomes "it did what I told it, not what I wanted".

## Contract-locked dispatches when the task crosses a boundary

When one task splits across a boundary (Rust backend + TypeScript frontend, two services that talk over an API, a producer and a consumer), do not dispatch the two halves with separate "figure out the shape with the other agent" instructions. **Design the boundary in the dispatch prompt** and hand the same locked contract to both subagents. Each implements its side to the same wire format and the integration is mechanical because the seam was decided up front.

What goes in the contract block of the prompt:

- **Types crossing the boundary**, with field names, casing, and serialization shape. Both sides write to these names verbatim.
- **The verb surface**: command names, argument shapes, return shapes, event channel names, event payload shapes.
- **Direction of error handling**: how errors come back across the boundary.
- **What each side owns**: backend agent touches Rust files only, frontend agent touches TypeScript files only, neither touches both.

The result, when this works, is that the integration is a copy of disjoint files into main with zero merge logic. When it fails, the failure is a contract drift you can see in one diff. Either is better than the per-side "guess the shape" flailing you get without it.

This is also where parallel-dispatch becomes safe with very different work: by partitioning the file surface (Rust vs TypeScript) AND locking the wire contract, two genuinely independent dispatches converge without coordination. See `parallel-dispatch` for the isolation half.

For a Nominal Tauri app the wire contract follows `nominal-tauri-ipc-shape`. Brief subagents on that skill or paste the relevant section into the dispatch.

## When a dispatch stalls or fails

A returned dispatch is one signal. A **stalled** dispatch is another, and a **partial** return is a third. Each deserves a different response.

**Stalled (no progress for an extended window).** The harness will eventually kill a stalled subagent. Before that fires, decide whether the dispatch was underspecified or whether the subagent hit a real environmental landmine (a path that does not resolve, a tool that timed out, a network blip on a fetch). If the latter, the recovery is to re-dispatch with the workaround in the prompt, see `worktrees` for the path-dep resolution example. If the former, refine the brief and re-dispatch.

**Partial return (some changes on the worktree, no clean report).** Check what landed. If the work is structurally sound for the parts it touched, **salvage it**: copy what is good into main as if it had returned cleanly, finish the rest in the lead thread inline, and document the salvage in the session log so the next reader knows the result is not from one full dispatch. If the partial work is incoherent (half a refactor, contradictory edits, broken intermediate state), discard and re-dispatch.

**Compiler-clean but spec-wrong return.** This is the stage-one fail in the two-stage review. The subagent solved a different problem or skipped part. Do not proceed to stage two, re-dispatch with the gap called out.

The lead thread is the holder of the project's actual state. A dispatch that did not complete on its own terms is not a project failure, it is a signal to be processed. Process it explicitly. Pretending a partial return is a clean return is how silent drift accumulates.

## Two-stage review of the result

A returned dispatch is a proposal. Review it in two distinct passes, in order.

**Stage one, spec compliance.** Did it do what the dispatch asked. Compare the result against the goal and definition of done. If it solved a different problem, or skipped part of the task, stage one fails. Do not proceed to stage two, send it back.

**Stage two, code quality.** Given that it met the spec, is the code sound. Conventions followed, no obvious defects, validators green, no collateral damage to files it should not have touched. Severity-grade what you find, see `code-review`.

Only after both stages pass does the dispatch integrate.

## Red flags

| Symptom | What it means |
|---|---|
| The subagent asked a clarifying question it should not have needed | The dispatch was underspecified. Brief more completely. |
| The dispatch covered several tasks | Split it. One task per dispatch. |
| You reviewed code quality before checking spec compliance | Wrong order. A well-built wrong thing still fails stage one. |
| The result was integrated without running validators | Validators are the floor. Run them before integrating. |
| The subagent changed files outside its scope | Collateral damage. Stage two should catch it. |
| Two dispatches were sent across a backend/frontend boundary without a locked contract | They will drift on field names or shapes. Put the contract in both prompts. |
| A subagent stalled and the lead is not sure why | Either the brief was unclear or the environment surprised the agent. Both have specific fixes; pick one before re-dispatching. |
| A partial return was integrated as if it were a clean return | The lead is now carrying an inaccurate picture of what shipped. Salvage explicitly and note the salvage. |

## Rationalizations to reject

- "The subagent will figure out the conventions." It will not, it has no memory of them. State them in the dispatch.
- "It met the spec, that is good enough." Spec compliance is stage one of two. Quality is still owed.
- "The dispatch is a bit broad but the subagent can handle it." Broad dispatches are hard to review and isolate. Scope tight.
- "The two parallel halves can negotiate the shape between themselves." They cannot, they cannot see each other. Lock the boundary in both prompts.
- "A stalled dispatch must be the subagent's fault." Sometimes the brief was unclear, sometimes the environment surprised it. Diagnose before re-dispatching.
- "A partial return is close enough to a clean one." It is not. Salvage explicitly so the lead's picture of state matches reality.
