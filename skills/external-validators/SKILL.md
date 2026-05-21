---
name: external-validators
description: Use whenever setting up, running, or relying on the tools that enforce correctness on a Nominal project - pre-commit, the Rust compiler, the type system, linters, CI. Establishes why Nominal leans on deterministic gates and how to treat them.
---

# External Validators

## Overview

An external validator is any deterministic gate that enforces a rule without depending on anyone remembering it: pre-commit hooks, the Rust compiler, the type system, clippy, tsc, the test suite, CI. Nominal leans on these hard, and on purpose.

The reason: a rule that a human or an agent must remember is a rule that will eventually be missed. A validator does not get tired, does not forget, and is not optional. This is also what makes the Nominal model safe, your human partner writes zero Rust and Claude authors the code, and that works because the compiler and the type system catch the class of errors a human reviewer otherwise would. The validator is a tireless teammate. Treat it as one.

## When this triggers

Fires when setting up project tooling, when validators run, when one fails, and when deciding whether work is allowed to proceed.

## How to treat validators

1. **Validators encode two kinds of rule.** Language rules (formatting, type correctness) and our rules (clippy with warnings denied, large-file limits, no merge-conflict markers). Both are enforced the same way, by the gate. The pre-commit config is where our rules become non-optional.
2. **Green is the floor, not the goal.** Validators passing means the work cleared the minimum bar. It does not mean the work is good. Code review and verification still apply, see `code-review` and `verification-before-completion`.
3. **A validator failure is information, not an annoyance.** When clippy or the compiler rejects something, it found a real problem. Fix the cause, see `systematic-debugging`. Never silence a validator to make it pass.
4. **Do not weaken a validator to get unblocked.** Disabling a lint, lowering a threshold, allowing a warning, skipping a hook, all of that removes the gate instead of clearing it. If a validator is genuinely wrong, change it deliberately and document why, do not bypass it under pressure.
5. **Document why config deviates.** When a project's validator config departs from the standard (for example, Tauri puts Cargo.toml in src-tauri/ so the Rust hooks must be local, or tsconfig is JSONC so strict JSON checking must exclude it), write the reason in a comment. The next reader, often a future you, needs the why.
6. **Run validators at the boundaries.** Before work starts, to confirm a clean baseline. Before a dispatch returns. Before a branch is finished. See `worktrees` and `verification-before-completion`.

## Red flags

| Symptom | What it means |
|---|---|
| A lint was disabled or a threshold lowered to get a commit through | The gate was removed, not cleared. Fix the cause. |
| A pre-commit hook was skipped under time pressure | The validator is not optional. Skipping it defeats the point. |
| A warning was allowed to pass clippy | Nominal denies warnings. A warning is a failure. |
| Validator config deviates with no comment explaining why | The next reader cannot tell intent from mistake. Document it. |
| "Validators pass" was treated as "the work is done" | Green is the floor. Review and verification still apply. |
| A validator failure was treated as noise | It found a real problem. Read it, fix the cause. |

## Rationalizations to reject

- "This warning is harmless, I will allow it." Nominal denies warnings so the gate stays meaningful. Fix it.
- "I will skip the hook just this once." Just-this-once is how the gate erodes. Run it.
- "The validator is being annoying." The validator found something. Annoyance is not a counterargument.
- "I will document why the config is weird later." Later does not happen. Comment it when you write it.
