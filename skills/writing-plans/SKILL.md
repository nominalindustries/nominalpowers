---
name: writing-plans
description: Use when a feature or milestone needs to be broken down before the lead thread can dispatch it. Produces a plan of small, scoped, independently dispatchable tasks, each with enough detail that a subagent can execute it without guessing.
---

# Writing Plans

## Overview

Before the lead thread can dispatch work, the work has to be broken into tasks. A plan is that breakdown: a set of small, scoped units, each one dispatchable to a subagent. A good plan is not a grand document, it is a queue of things small enough to hand off cleanly and verify quickly.

## When this triggers

Fires when a feature, milestone, or build needs decomposition before execution: after a spec exists (from `complaint-driven-development` or a design) and before dispatching begins.

## How to write a plan

1. **Make each task small.** A task should be a focused unit of work, not an epic. Small tasks are easier to brief, easier to verify, and easier to isolate when one goes wrong. If a task feels large, split it.
2. **Make each task self-contained.** A task should be dispatchable on its own: the subagent gets this task's briefing and can execute it. A task that cannot be explained without the whole project's context is too entangled, untangle it.
3. **Specify each task concretely.** For each: what it achieves, which files it touches, the definition of done, the validators that must pass. Vague tasks become subagent guesses.
4. **Map the dependencies.** Note which tasks depend on which. Independent tasks can be dispatched in parallel, see `parallel-dispatch`. Dependent tasks must be sequenced. The plan should make the dependency graph obvious.
5. **Order for a clean baseline.** Sequence so that each task starts from a state where the validators can pass. Do not plan a task that necessarily leaves the tree broken for the next one.
6. **The plan is a living queue.** As tasks complete and the picture sharpens, the plan can change. It is a working tool, not a contract. Do not over-specify tasks far in the future that will likely shift.

## Red flags

| Symptom | What it means |
|---|---|
| A task is too big to brief in one dispatch | Split it into smaller tasks. |
| A task cannot be understood without the whole project context | Too entangled. Untangle it or note the dependency. |
| Tasks have no definition of done | A subagent cannot verify it finished. Add it. |
| The dependency order is unclear | The lead thread cannot decide what to parallelize. Map it. |
| The plan specifies far-future tasks in fine detail | Those will shift. Plan them coarsely, refine when near. |

## Rationalizations to reject

- "I will plan it all in full detail up front." Far-future tasks shift as earlier ones complete. Detail the near ones, sketch the rest.
- "This task is fine as one big unit." Big tasks are hard to dispatch, verify, and isolate. Split.
- "The dependencies are obvious, I will not write them down." Obvious to you now is not obvious to the lead thread mid-build. Map them.
