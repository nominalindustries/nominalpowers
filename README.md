# nominalpowers

Engineering skills for building Nominal Industries software with Claude: how work gets planned, dispatched to subagents, validated by tools rather than memory, and finished cleanly.

## The problem

A software build with several parts needs more than a capable model. Left to itself, an assistant working on a multi-part feature loses the plan across context boundaries, declares work done because it looks done, and depends on remembering the project's rules rather than having them enforced. The result is work that has to be re-checked by hand, which is the cost the assistant was supposed to remove.

nominalpowers is the operating model that fixes that for Nominal projects. A **lead thread** holds the architecture and the plan, **dispatches** scoped tasks to subagents with briefs complete enough to execute without guessing, reviews what comes back in two stages, and integrates it. Correctness is enforced by **external validators** (the compiler, the type system, pre-commit, CI) so it does not depend on anyone, human or model, remembering the rules. Nothing is declared done without evidence.

The workflow ideas come from the [superpowers](https://github.com/obra/superpowers) project, rewritten in Nominal's own vocabulary and practice, with deliberate divergences where Nominal works differently. The clearest one is staged TDD, engaged once an app's core has solidified, rather than TDD from the first line.

## Skills

Twenty-four skills. One is the spine, the rest trigger on their own.

**The spine:**

- **using-nominalpowers** - the lead-thread model, the vocabulary, the external-validator philosophy, and the roster below. Read first, stays active for engineering work.

**Planning and dispatch:**

- **complaint-driven-development** - turning a complaint about software (existing or wished for) into a feature spec, brainstorm style, without jumping to code.
- **writing-plans** - breaking a feature or milestone into small, scoped, independently dispatchable tasks.
- **lead-thread-workflow** - running a build as a lead thread that plans, dispatches, integrates, and verifies.
- **dispatching-subagents** - briefing one dispatch so the subagent can execute without guessing, and the two-stage review of its result.
- **parallel-dispatch** - running several independent dispatches at once without their work colliding.
- **worktrees** - isolated git workspaces with a verified clean validator baseline before any work starts.

**Correctness and completion:**

- **external-validators** - why Nominal leans on deterministic gates (pre-commit, compiler, type system, linters, CI) and how to treat them.
- **tdd-mode** - test-driven development as a deliberately engaged phase: the early phase, the switch, and TDD mode itself.
- **systematic-debugging** - a four-phase root-cause process instead of guess-and-check patching.
- **code-review** - requesting and receiving severity-graded review inside the lead-thread workflow.
- **verification-before-completion** - proving work is done with evidence before claiming it. "It works" is a claim, not a verification.
- **finishing-a-branch** - the deliberate merge, PR, or discard decision and the cleanup after it.

**Architecture and conventions:**

- **design-for-failure** - blast-radius isolation as the default structural principle: a failure in one part cannot take down the rest.
- **nominal-four-doc-standard** - the four-doc repo layout (README, CLAUDE, HUMANS, PLAN), the ambient-state stream file, and the invariants ladder.
- **nominal-app-aesthetic** - every app picks a coherent aesthetic spine at scaffold time, and "aesthetic complete" is a release gate alongside "features complete".
- **nominal-sdk-extraction** - deciding what belongs in an app versus a shared Rust crate, and the workspace conventions for the shared ones.

**Tauri app patterns:**

- **nominal-tauri-scaffold** - the standard Tauri 2 project structure, stack defaults, and validator setup for a new Nominal app.
- **nominal-tauri-state-pattern** - the shared backend state pattern, lock discipline, and the best-effort save helper.
- **nominal-tauri-ipc-shape** - the command and event surface that crosses the Rust and TypeScript boundary, and its conventions.
- **nominal-tauri-capabilities** - wiring capability files, and the recurring landmines behind frontend features that silently do nothing.
- **nominal-persistent-collections** - persisting collections of dynamic things (tabs, sessions, bookmarks) as static shape and restoring them safely at boot.
- **nominal-async-cleanup-patterns** - cancellation and teardown of background work: the abort traps, the cascade pattern, and Drop order.
- **nominal-updater-pipeline** - the update and distribution path: deploy script, release-notes site, the R2 and Worker chain, and signing.

## Bundled configuration

`reference/tauri-app-pre-commit-config.yaml` is the standard pre-commit configuration that `nominal-tauri-scaffold` and `external-validators` describe. `.lsp.json` configures `pyright-langserver` (Python) and `rust-analyzer` (Rust) for real-time diagnostics in Claude Code. The plugin carries the configuration, not the binaries, so each language server has to be installed and on `PATH`.

## Installation

nominalpowers is a Claude plugin and installs through the Nominal plugin marketplace on every surface (chat, Code, and Cowork). In Claude Code:

```
/plugin marketplace add nominalindustries/nominal-marketplace
/plugin install nominalpowers@nominal-marketplace
```

In the chat and Cowork apps, add the marketplace in the plugin settings and install nominalpowers from it. Anthropic's [plugin guide](https://support.claude.com/en/articles/13837440-use-plugins-in-claude#h_9ce531e6c7) walks through the steps.

## Related plugins

nominalpowers is the application engineering member of a small family. [spicypowers](https://github.com/nominalindustries/spicypowers) covers communication and working style and is assumed to be active alongside this one. [sparkypowers](https://github.com/nominalindustries/sparkypowers) covers infrastructure. They compose but do not depend on each other.

## Status

Early. The workflow skills are stable in daily use. The Tauri pattern skills are extracted from shipped apps and grow as new patterns earn their place. A further wave of architecture skills (build tooling order, tier placement across Rust, BEAM, and Workers, and shared crate scaffolding) is planned but not written, to avoid guessing at details before they are settled.

## License

MIT.
