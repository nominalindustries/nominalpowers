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

## Rationalizations to reject

- "The subagent will figure out the conventions." It will not, it has no memory of them. State them in the dispatch.
- "It met the spec, that is good enough." Spec compliance is stage one of two. Quality is still owed.
- "The dispatch is a bit broad but the subagent can handle it." Broad dispatches are hard to review and isolate. Scope tight.
