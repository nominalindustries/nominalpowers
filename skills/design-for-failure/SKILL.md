---
name: design-for-failure
description: Use when making an architecture or structural decision on a Nominal project - how to split state, isolate components, organize infrastructure, or scope a change. Applies the core Nominal principle: design so that a failure in one part cannot take down the rest.
---

# Design for Failure

## Overview

The core Nominal architecture principle is design for failure: assume things will break, and structure the system so that a failure stays contained. The unit of thinking is blast radius, how far the damage spreads when something goes wrong. Good design keeps the radius small. This is not pessimism, it is the discipline that lets the system fail safely instead of catastrophically.

## When this triggers

Fires on architecture and structural decisions: splitting state, isolating components, organizing infrastructure, scoping a change, deciding what shares a boundary with what.

## How to apply it

1. **Isolate by concern.** Things that fail for different reasons, or change for different reasons, belong behind separate boundaries. The standing example: separate Terraform state for stateful resources versus compute resources, so a compute change cannot endanger stateful infrastructure. The same logic applies broadly, separate state per concern.
2. **Ask where the blast radius reaches.** For any change or any coupling, ask: if this fails, what else goes down with it. If the answer is "more than it should", add a boundary.
3. **Default to separation, justify coupling.** Two things sharing state, a process, or a failure domain should be a deliberate choice with a reason. Coupling by default is how a small failure becomes a large one.
4. **Keep failures observable and recoverable.** A contained failure should be visible (you can tell what broke) and recoverable (fixing it does not require touching everything). Isolation that hides failures is not isolation.
5. **Apply it at every scale.** The principle holds for infrastructure (separate state files, per-environment isolation), for application architecture (the three Nominal tiers as separable layers), and for a single change (a worktree isolates the change from the baseline, see `worktrees`). Same idea, different scale.
6. **Remember the universal principle.** "It did what I told it, which was not what I wanted." Systems do exactly what they are structured to do. Designing for failure means structuring them so that what they do under failure is survivable.

## Red flags

| Symptom | What it means |
|---|---|
| Stateful and compute resources share one state file | A compute change can now endanger stateful infrastructure. Split them. |
| Two things are coupled with no stated reason | Coupling should be deliberate. Default to separation. |
| A single failure would take down unrelated parts | The blast radius is too wide. Add a boundary. |
| A change was scoped without asking what it could take down | Always ask where the blast radius reaches. |
| Isolation was added but failures are now invisible | Contained must still mean observable and recoverable. |

## Rationalizations to reject

- "Keeping it in one place is simpler." Simpler until it fails and takes everything with it. Separate by concern.
- "These two things are related, so they belong together." Related is not the test. Failing-for-the-same-reason is. Justify the coupling.
- "This change is small, the blast radius does not matter." Small changes cause large outages when the radius is wide. Ask anyway.
