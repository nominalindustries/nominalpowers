---
name: verification-before-completion
description: Use before declaring any piece of engineering work done - a dispatch, a task, a fix, a branch. Requires proving completion with evidence rather than asserting it. "It works" is a claim, not a verification.
---

# Verification Before Completion

## Overview

"It works", "that should do it", "the task is complete", these are claims. A claim is not verification. Verification is evidence: the validators ran and passed, the behavior was observed, the original problem is confirmed gone. Nominal does not accept claimed completion. This is the engineering form of "it did what I told it, which was not what I wanted", the gap between believing work is done and it actually being done.

## When this triggers

Fires before declaring anything done: a returned dispatch, a completed task, a bug fix, a branch ready to finish.

## How to verify

1. **Run the external validators, all of them.** cargo fmt, clippy with warnings denied, tsc, the test suite, whatever the project gates on. Not a subset. Green across the board, see `external-validators`.
2. **Confirm the actual goal, not a proxy.** Check the thing the work was supposed to achieve. For a bug fix, the original reproduction no longer fails. For a feature, the feature does what the spec said. Compiling is not the same as working.
3. **Check for collateral damage.** Confirm nothing adjacent broke. A change can pass its own tests and still break something else. The full validator suite is part of how you catch this.
4. **State the evidence, not the conclusion.** When reporting completion, say what was checked and what the result was, not just "done". "Validators green, the failing repro now passes, full suite passes" is verification. "It works" is not.
5. **If you cannot verify it, do not claim it.** If something blocks verification, say that plainly. Unverified work reported as done is worse than work reported as unverified, because it stops anyone else from checking.

## Red flags

| Symptom | What it means |
|---|---|
| "Done" was reported without validators run | A claim, not verification. Run them. |
| Only the directly-related test was run | Collateral breakage goes unseen. Run the full suite. |
| Compiling was treated as working | Compiling is the floor. Confirm the actual goal. |
| The report says "it works" with no evidence | State what was checked and the result. |
| Work was claimed done while something blocked verification | Unverifiable work reported as done hides the gap. Say it is unverified. |

## Rationalizations to reject

- "It is a small change, it obviously works." Obvious is a claim. Small changes break things too. Run the validators.
- "It compiled, so it is done." Compiling is necessary, not sufficient. Confirm the goal.
- "I will say done and someone will catch it if not." Reporting done stops others from checking. Verify first or say unverified.
