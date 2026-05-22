---
name: nominal-sdk-extraction
description: Use when deciding whether a piece of Rust code in a Nominal Tauri app belongs in `src-tauri/` or in a shared crate under `nominal-sdks-rust/`. Covers the extraction rule, the workspace conventions (`Arc<Inner>` shell, figment config, `NominalError`-rooted error chain), the consumer Cargo.toml shape for cross-repo path deps, and the sub-crates-over-feature-flags scale path.
---

# Nominal SDK Extraction

## Overview

Nominal apps are deliberately thin shells over shared Rust crates. The reusable primitives, generators, parsers, clients, and domain logic live in the `nominal-sdks-rust/` Cargo workspace. The app repo holds only the IPC handlers, the UI glue, and the app-specific configuration. If generation or domain logic shows up in `src-tauri/`, it is in the wrong place.

The payoff is that the next Nominal app gets the primitive for free, the test surface lives next to the code that uses it across all consumers, and the app repos stay small enough to scaffold quickly.

The cost is coordinating two repos (the app on GitHub, the SDK workspace on GitLab) and the discipline to extract on the second use rather than the third. It is worth paying.

## When this triggers

- Reviewing a PR that adds Rust code to a Nominal Tauri app's `src-tauri/`.
- Starting a new app that needs a primitive a previous app already implemented.
- Adding a new public surface to an existing SDK crate.
- Deciding whether a primitive is too small to extract (almost always, the answer is "extract it now, it grows").

## The extraction rule

A primitive belongs in `nominal-sdks-rust/` if any of these are true:

1. **It is used by more than one Nominal app**, or one app plus one cowork plugin or CLI.
2. **It is plausibly going to be used by another Nominal app within the next year.** The plausibility threshold is "could imagine the use case", not "have the use case in hand". Extracting late costs more than extracting early.
3. **It captures a Nominal-wide convention** that should be enforced by the type system (e.g., the `NominalError` enum, configuration shapes, error-rooted result types).

A primitive stays in `src-tauri/` only if:

- It is glue that adapts an SDK primitive to a specific app's UI shape (IPC opts structs with `#[serde(rename_all = "camelCase")]`, frontend-flavored option translations, app-specific mixing helpers).
- It is throwaway scaffolding that will be deleted within the same iteration.

## Workspace conventions

The `nominal-sdks-rust/` workspace lives at `~/code/github.com/nominalindustries/nominal-sdks-rust/` (GitLab origin). It enforces a specific shape across every crate it ships:

- **`Arc<Inner>` shell pattern** for crates that hold any state. The public type is a thin `Arc`-wrapping handle that clones cheaply; the heavy state lives in `Inner`.
- **figment-based configuration.** Crates that take configuration use figment's layered config (defaults → file → env). Plain `serde::Deserialize` is not enough; the figment shape lets the same crate run in app, CLI, and test contexts without rewriting.
- **`NominalError`-rooted error chain.** Every crate's error type either is or wraps `nominal_core::NominalError`. App code can `?` across crate boundaries without per-crate error matching.
- **Doc tests on the public surface.** Each public method gets a doc-comment example that compiles and runs as part of `cargo test`. The examples are the API documentation.
- **`CARGO_TARGET_DIR=/tmp/nominal-target`** for performance. The workspace builds 30+ crates; sharing a tmp target across builds saves minutes per session.

A new SDK crate that does not conform to these is not done.

## Consumer Cargo.toml shape

App repos consume SDK crates by relative path, two levels up:

```toml
[dependencies]
nominal-secrets = { path = "../../nominal-sdks-rust/nominal-secrets", features = ["tauri"] }
nominal-wordlists = { path = "../../nominal-sdks-rust/nominal-wordlists" }
nominal-entropy = { path = "../../nominal-sdks-rust/nominal-entropy" }
```

The path works because the on-disk directory layout stays uniform (`~/code/github.com/nominalindustries/<repo>/`) regardless of which remote (GitHub or GitLab) each repo points at. SuperForge, SuperEntropy, and SuperSerial all use this shape.

When the SDK workspace eventually publishes to a private registry, the path deps become version deps without restructuring the consumer Cargo.toml beyond the dep line itself.

## Sub-crates over feature flags

When an SDK crate grows past a comfortable single-crate size, the Nominal scale path is to split into sub-crates, not to add Cargo `[features]`.

Example: `nominal-wordlists` currently ships 10 dictionaries (EFF Long, EFF Short, Heroku-style, Scientists, Cryptographers, Buzzwords, Space, Animals, Food, Fin Auth). If it grows past comfortable, the split is `nominal-wordlists-eff`, `nominal-wordlists-heroku`, `nominal-wordlists-themed`, each independently consumable.

Why not features?

- Features compose at the workspace level and produce surprising binary-size differences across consumers.
- Features make doc tests harder (a doc test depending on a feature-gated dictionary needs feature annotations).
- Sub-crates let each consumer pull exactly what it uses without per-feature flag wrangling.

The principle: when a crate is doing more than one thing, split it. Cargo features are for genuine compile-time variants (`tauri` glue vs no `tauri`, `tokio` runtime vs `async-std`), not for content selection.

## Cross-repo workflow

App and SDK changes that ship together still split into two commits across two repos:

1. SDK change lands first (new public surface, new method, new error variant). Tests pass in the SDK workspace.
2. App change consumes the new surface. Tests pass in the app repo.

The same is true in reverse for renames or breaking changes: deprecate in the SDK first, migrate the consumer, then remove the deprecated surface in a follow-up SDK release.

The on-disk layout makes this cheap: both repos are checked out in the same workspace tree, so the change is two `git` operations, not a cross-repo coordination ritual.

## Red flags

| Symptom | What it means |
|---|---|
| Generation logic, parsers, or domain primitives in `src-tauri/` | Belongs in an SDK crate. Extract on the second use, ideally on the first. |
| New SDK crate without `Arc<Inner>` shell, figment config, or `NominalError` root | Does not conform to workspace conventions. Update before merging. |
| App Cargo.toml uses a published version of a Nominal crate but a path version is available | Switch to path deps so local SDK changes compose without a registry round-trip. |
| Sibling Nominal app reimplements a primitive that another app already ships | Pull the primitive out of the first app into the SDK workspace, consume from both. |
| New Cargo feature flag added to an SDK crate to select content (which dictionary, which wordlist, which client) | Use sub-crates instead. |
| App and SDK changes in one commit across one repo | Two repos, two commits, SDK first. |

## Rationalizations to reject

- "It is a one-off, will not be reused." We hear this on the first use and regret it on the second. The cost of extracting at the second use exceeds the cost of extracting at the first.
- "The SDK workspace is overhead for this small thing." The overhead is paid once at workspace setup time (already done) and amortizes across the portfolio.
- "Cargo features are simpler than sub-crates." For genuine compile-time variants they are. For content selection they introduce more surprise per use than a sub-crate.
- "Cross-repo coordination is too painful." It is two commits in two repos with the same on-disk layout. The pain is in not extracting, not in extracting.
