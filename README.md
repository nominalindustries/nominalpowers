# nominalpowers

A Claude plugin of engineering skills for Nominal Industries projects. It is the code layer: how Nominal software gets planned, dispatched, built, validated, and finished. Its sibling, `spicypowers`, is the operating layer (communication, intake, status, trackers). The two are designed to be used together.

nominalpowers takes the workflow ideas proven by the `superpowers` project and rewrites them in Nominal's own vocabulary and practice, with deliberate divergences where Nominal works differently (notably staged TDD rather than strict-always TDD).

## The model

Nominal projects are built with a **lead thread** (the lead developer, holding architecture and plan) that **dispatches** scoped tasks to subagents, then integrates and verifies their work. Correctness is enforced by **external validators**, the compiler, the type system, pre-commit, and CI, so that work does not depend on anyone remembering the rules.

## Skills

**The spine (keep active for engineering work):**

- **using-nominalpowers** - the lead-thread model, the vocabulary, the core principles, the roster. Read it first.

**Workflow:**

- **complaint-driven-development** - turning a complaint about software into a feature spec.
- **lead-thread-workflow** - running a project as a lead thread orchestrating dispatched subagents.
- **dispatching-subagents** - briefing one dispatch and applying the two-stage review to its result.
- **parallel-dispatch** - running several subagents at once without their work colliding.
- **worktrees** - isolated git workspaces with a clean validator baseline before work starts.
- **writing-plans** - breaking a feature into small, dispatchable tasks.
- **tdd-mode** - engaging test-driven development as a deliberate phase once an app's core has solidified.
- **systematic-debugging** - four-phase root-cause debugging.
- **external-validators** - the principle and practice of deterministic correctness gates.
- **code-review** - requesting and receiving severity-graded review.
- **verification-before-completion** - proving work is done with evidence before claiming it.
- **finishing-a-branch** - the deliberate merge, PR, or discard decision and the cleanup after.

**Architecture:**

- **design-for-failure** - blast-radius isolation as the default architecture principle.
- **nominal-tauri-scaffold** - bootstrapping a new Nominal Tauri 2 app with the standard layout and validators.

## Reference

`reference/tauri-app-pre-commit-config.yaml` is the standard Nominal Tauri pre-commit configuration that `nominal-tauri-scaffold` and `external-validators` describe.

## Planned, not yet included

A second wave of architecture skills is planned: `nominal-forge` (the Prism/Anvil/Crucible build-tooling order), `three-tier-placement` (Rust/Tauri vs Gleam/BEAM vs CF Workers), and `nominal-crate-scaffolding` (the nominal-* Rust crate conventions). These were deferred to avoid guessing at details.

## Status

Version 0.1.0. Early. Skills will evolve with use.
