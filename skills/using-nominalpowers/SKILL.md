---
name: using-nominalpowers
description: Read this first and keep it active for any engineering work on a Nominal Industries project. Establishes the lead-thread development model, the shared vocabulary, the external-validator philosophy, and the rest of the nominalpowers skills. This is operating context, it frames the whole session.
---

# Using Nominalpowers

## What this is

Nominalpowers is the engineering plugin: how Nominal Industries software gets built. Its sibling, spicypowers, is the operating layer (communication, intake, status, trackers). This plugin is the code layer. The two are designed to be used together, spicypowers still applies here, this plugin adds the engineering machinery on top.

This skill is the spine. It does not finish. It frames every engineering response. The other skills trigger per-situation and are listed at the bottom.

## The lead-thread model

Nominal projects are built with one orchestrating thread and dispatched subagents.

- The **lead thread** (titled like "AppName Development Lead Thread") is the lead developer. It holds the architecture, the plan, and the integration. It does not do all the work itself.
- A **dispatch** is a unit of work handed to a subagent: a scoped task with everything the subagent needs. The lead thread dispatches, the subagent executes in isolation, the lead thread integrates and verifies the result.
- Your human partner is the human in the lead thread. They bring architecture and constraints. The lead thread orchestrates. This is the division of labor: your human partner decides what and why, the system handles how.

Your human partner writes zero Rust. Claude and Cowork are the code authors. This works because Nominal leans hard on external validators (see the `external-validators` skill): the compiler and the type system catch what a human reviewer otherwise would.

## Vocabulary

- **Lead thread** - the orchestrating thread, the lead developer. Superpowers calls this the orchestrator.
- **Dispatch** - handing a scoped task to a subagent. Both noun and verb.
- **Complaint-driven development (CDD)** - the Nominal intake style: your human partner complains about an app that exists or wishes existed, and the complaint is turned into features. Has its own skill.
- **TDD mode** - test-driven development engaged as a deliberate phase once an app's core has solidified, not a from-day-one rule. Has its own skill.
- **External validator** - any deterministic gate that enforces the rules without depending on memory: pre-commit, the Rust compiler, the type system, CI.
- **Nominal Forge** - the Prism, Anvil, Crucible build-tooling order. (Architecture skill, second wave.)

Spicy-brain vocabulary (brain dump, thought parade, SBTB) lives in spicypowers' `using-spicypowers`.

## Core principles

- **Design for failure.** Blast-radius isolation is the default. Separate state for separate concerns. See `design-for-failure`.
- **External validators over vigilance.** A rule a human or agent must remember is a rule that will be missed. Encode it in a validator. See `external-validators`.
- **It did what I told it, which was not what I wanted.** The universal automation failure. Catch intent, not just literal instruction.
- **Evidence over claims.** "It works" is not verification. See `verification-before-completion`.

## The rest of nominalpowers

### Engineering practices

- **complaint-driven-development** - turning a complaint into a feature spec.
- **lead-thread-workflow** - running a project as lead thread plus dispatched subagents.
- **dispatching-subagents** - the mechanics of one dispatch and the two-stage review of its result.
- **parallel-dispatch** - running several subagents at once safely.
- **worktrees** - isolated git workspaces, clean baseline before work starts.
- **writing-plans** - breaking work into small, dispatchable tasks.
- **tdd-mode** - engaging test-driven development as a phase once the core has solidified.
- **systematic-debugging** - four-phase root-cause debugging.
- **external-validators** - the principle and practice of deterministic gates.
- **code-review** - requesting and receiving severity-graded review.
- **verification-before-completion** - proving work is done before claiming it.
- **finishing-a-branch** - merging, PR, or discarding, and cleaning up.
- **design-for-failure** - blast-radius isolation in architecture.

### Nominal app conventions

- **nominal-four-doc-standard** - the four-doc layout (README, CLAUDE, HUMANS, PLAN) plus `notes/STREAM.md` and the invariants ladder.
- **nominal-tauri-scaffold** - bootstrapping a new Nominal Tauri 2 app.
- **nominal-tauri-capabilities** - the capability file landmines (drag attribute, clipboard write/read, updater-process pair).
- **nominal-sdk-extraction** - when code belongs in `nominal-sdks-rust` rather than the app repo.
- **nominal-updater-pipeline** - the deploy script + R2 + Cloudflare Worker + mini-site chain.
- **nominal-app-aesthetic** - per-app aesthetic spine, treated as a release gate.
