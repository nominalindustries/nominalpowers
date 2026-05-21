---
name: tdd-mode
description: Use to decide when and how to apply test-driven development on a Nominal project. TDD is not a from-day-one rule here, it is a mode engaged deliberately once an app's core features have solidified. Covers the early phase, the switch, and TDD mode itself.
---

# TDD Mode

## Overview

Test-driven development is a good discipline, but strict TDD from day one fights early-stage Nominal work. When an idea is not yet formed, the design shifts fast, and tests written against a moving design get thrown away with it, wasting effort and context. So on Nominal projects TDD is not a baseline rule. It is a **mode**, engaged deliberately once the core has solidified. "TDD mode is on" is part of what it means for an app to be heading toward a real 1.0.

What TDD mode is really for, the framing that matters most: it is a regression net for future-you. The real risk is not this week, when everyone remembers how the pieces fit. It is the idea a year from now that quietly breaks something nobody remembers depends on it. The test is the memory that neither your human partner nor Claude will still have in twelve months. That is the point of engaging it, not adherence to a strict rule.

This is a deliberate divergence from strict-always TDD. It is not permission to skip tests, it is a sequencing decision.

## When this triggers

Fires when deciding how to handle tests on a project: at the start (which phase are we in), when the core stabilizes (time to switch), and during TDD mode itself.

## The two phases

### Early phase, before TDD mode

The design is still moving. The core features are not settled.

- Do not write tests test-first against an unsettled design.
- Still add tests where they clearly earn their place: a piece of logic that has stabilized, a tricky function worth pinning, and especially **a bug or regression**. When a bug is found, a test that captures it is always worth writing, in any phase.
- The goal of this phase is a working, exercised core, not coverage.

### The switch

TDD mode is engaged when the app's core features have solidified, the design is no longer churning. This is an explicit decision, your human partner says "engage TDD mode on this project now" or equivalent. Treat the switch as a real milestone, it marks the app turning toward 1.0.

### TDD mode, after the switch

Once engaged, TDD applies: for new work, write the failing test first, watch it fail, make it pass, refactor. The core is stable enough now that tests written against it will last. From here, untested new behavior is a gap, not a phase. Each test added is one more thing future-you cannot accidentally break without the suite catching it.

## Red flags

| Symptom | What it means |
|---|---|
| Strict test-first on a design that is still churning | Wrong phase. Tests will be thrown away with the design. |
| A bug was fixed with no test capturing it | Bug and regression tests are always worth it, every phase. |
| The project is mature and core-stable but still has no TDD discipline | Time to engage TDD mode. Raise it. |
| "TDD mode" was assumed on without an explicit decision | The switch is a deliberate call. Confirm it. |
| Skipping tests entirely, citing the early phase | Early phase still tests stabilized logic and all bugs. It is not no-tests. |

## Rationalizations to reject

- "We are early phase, so no tests at all." Early phase still tests stabilized logic and every bug found. It is staged, not absent.
- "The design still moves a bit, so do not engage TDD yet." Some movement is fine. Engage when the core is solid, not when the app is frozen.
- "TDD mode is on, but this change is small." In TDD mode, small new behavior still gets a test first. That is the mode.
- "We will remember how this works, a test is redundant." Future-you, a year on, will not. The test is the memory you will not have.
