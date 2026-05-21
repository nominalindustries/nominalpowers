---
name: systematic-debugging
description: Use when something is broken - a failing test, a crash, wrong behavior, a validator error. Runs a four-phase root-cause process instead of guess-and-check patching, so the actual cause is found and fixed rather than a symptom masked.
---

# Systematic Debugging

## Overview

The fast-feeling way to debug is to guess at a fix and try it. It is usually slower, and it tends to mask symptoms rather than fix causes. Systematic debugging is four phases in order: understand, locate, fix, verify. The discipline is not skipping ahead.

## When this triggers

Fires whenever something is broken: a failing test, a crash, a wrong result, a validator error, unexpected behavior.

## The four phases

### Phase 1, understand

Before touching anything, know what is actually happening.

- Reproduce it reliably. A bug you cannot reproduce, you cannot confirm fixed.
- Read the actual error. The full message, the real stack trace, the exact failing assertion. Not a paraphrase.
- State the gap plainly: what is happening versus what should happen.

### Phase 2, locate

Find the real cause, not the place the symptom surfaced.

- Trace back from the symptom to its origin. Where the error appears is often not where it is caused.
- Form a hypothesis about the cause and confirm it with evidence, a log, a value, a test, before accepting it.
- Keep asking why until you reach a cause that explains the whole symptom, not just part of it.

### Phase 3, fix

- Fix the cause found in phase 2, not the symptom. A fix that makes the error disappear without explaining it is a mask, not a fix.
- Make the smallest change that addresses the cause. Sprawling fixes introduce new bugs.
- If a bug got this far, capture it with a test, see `tdd-mode`. A regression test is always worth writing.

### Phase 4, verify

- Confirm the original reproduction no longer fails.
- Run the external validators, see `external-validators`. The whole suite, not just the one test.
- Check you did not break something adjacent. Evidence, not assumption. See `verification-before-completion`.

## Red flags

| Symptom | What it means |
|---|---|
| You changed code before reproducing the bug | Phase 1 skipped. You cannot confirm a fix without a repro. |
| You fixed where the error appeared, not where it started | Phase 2 skipped. Symptom location is not cause location. |
| The error went away but you cannot explain why | That is a mask, not a fix. Find the cause. |
| You guessed at a fix and tried it | Guess-and-check. Run the phases in order. |
| The fix was verified by one test, not the suite | Adjacent breakage goes unseen. Run all validators. |
| A bug was fixed with no regression test | Phase 3 missed it. Bugs always earn a test. |

## Rationalizations to reject

- "I am pretty sure I know the cause, I will just fix it." Pretty sure is a hypothesis. Confirm it with evidence before fixing.
- "The error stopped, so it is fixed." An error stopping is not a cause explained. You may have moved the bug.
- "Reproducing it is slow, I will skip ahead." Without a repro you cannot verify the fix. The repro is the foundation.
