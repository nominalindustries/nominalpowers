---
name: nominal-tauri-scaffold
description: Use when starting a new Nominal Industries Tauri 2 application, or bringing an existing one up to the standard layout. Covers the standard project structure, the stack defaults, and the external-validator setup every Nominal Tauri app ships with.
---

# Nominal Tauri Scaffold

## Overview

Most Nominal Industries apps are Tauri 2 desktop applications, and they share a layout, a stack, and a validator setup. This skill is the scaffold: what a new Nominal Tauri app starts with so it is consistent with the rest of the portfolio and gated by external validators from commit one.

## When this triggers

Fires when starting a new Nominal Tauri 2 app, or when an existing one needs to be aligned to the standard.

## The standard layout

A Nominal Tauri 2 app puts the Rust crate in `src-tauri/`, not at the repo root. This is a Tauri convention and it has a consequence for tooling: anything that expects `Cargo.toml` at the root has to be told otherwise. The frontend lives in `src/` for apps with a frontend framework.

## Stack defaults

The common Nominal Tauri stack, adjust per app:

- **Tauri 2** as the desktop shell.
- **Rust** in `src-tauri/` for the backend. Your human partner writes zero Rust, Claude and Cowork author it, the compiler is the validator that makes that safe.
- **Frontend** varies: React with TypeScript for apps that need it, vanilla JS for simpler ones. The validator set follows the choice (a vanilla-JS app has no `tsc` or `vitest` hooks).
- **Local data** via SQLite, and a sync or edge tier where the app needs one.

Confirm the stack with your human partner per app rather than assuming. The layout and the validator philosophy are constant, the specific tiers are not.

## What ships at scaffold time

A new Nominal Tauri app starts with more than just the Tauri default. The full scaffold includes:

- **Identifier:** `industries.nominal.<appname>` in `tauri.conf.json` (`identifier` field). Reverse-DNS, not the bare app name.
- **Window defaults:** `tauri.conf.json` `windows[0]` carries a fixed size for utility apps that should not resize (set `width = minWidth` and `height = minHeight`). `titleBarStyle: "Overlay"` and `hiddenTitle: true` for the macOS hidden-titlebar pattern; the traffic-light buttons offset via `trafficLightPosition`. Worked examples in SuperEntropy and Nibble.
- **Plugin set:** Nominal-standard plugins added to `Cargo.toml` and the `Builder` chain at scaffold time: `tauri-plugin-clipboard-manager`, `tauri-plugin-store`, `tauri-plugin-window-state`, `tauri-plugin-log`. The updater pair (`tauri-plugin-updater` + `tauri-plugin-process`) is added when the app is ready to ship its first update; see `nominal-updater-pipeline`.
- **Capabilities:** `src-tauri/capabilities/default.json` carries every plugin's `:default` permission plus the explicit permissions for what the app actually calls. The recurring capability landmines (drag attribute, clipboard write/read, updater-process pair) live in `nominal-tauri-capabilities`.
- **Icons:** generated once from a source SVG via `npx @tauri-apps/cli icon path/to/icon.svg`. The full set lands in `src-tauri/icons/`. The release-notes mini-site's `site/<app>/icon.png` is a copy of `src-tauri/icons/icon.png`.
- **Four-doc + STREAM:** README, CLAUDE, HUMANS, PLAN at the repo root, plus `notes/STREAM.md` for ambient state. Roles, granularity, and the invariants-ladder pattern in `nominal-four-doc-standard`.
- **Aesthetic spine:** picked at scaffold time, not retrofitted. Palette, typography, motion notes written into CLAUDE.md so subagent dispatches inherit them. See `nominal-app-aesthetic`.

The principle is constant, the specifics adjust per app. A menu-bar utility (Nibble) needs less clipboard surface than a generator (SuperEntropy); a file-management app may need `fs:` capabilities a utility does not; a long-lived data app (DeepDive) carries SQLite that a stateless utility does not.

A sibling cowork plugin at `nominal-cowork-plugins/<appname>/` is **not** a scaffold-time concern. Add it once the app's vision and code have stabilized, so the plugin is not chasing the app in a circle. The payoff is biggest for apps that ship an MCP server, since the cowork plugin is the natural carrier for the MCP config and makes the integration easier to share across machines and collaborators. Building the plugin too early means re-doing it as the app finds its shape.

## External validators from commit one

Every Nominal Tauri app ships a `pre-commit` config before real work starts, see `external-validators`. The standard set:

- **File hygiene** - trailing whitespace, end-of-file, TOML/YAML/JSON checks, merge-conflict markers, a large-file ceiling.
- **Rust** - `cargo fmt` and `cargo clippy` with warnings denied. These must be **local hooks**, because the hosted Rust pre-commit hooks assume `Cargo.toml` is at the repo root and Tauri puts it in `src-tauri/`. The hook entries pass `--manifest-path src-tauri/Cargo.toml`.
- **TypeScript** - `tsc --noEmit` as a typecheck, for apps with a TS frontend. Skipped for vanilla-JS apps.
- **Frontend tests** - `vitest run` (via the `npm test` script so the hook tracks command changes), for apps wired for it.

Two standard deviations to carry forward, both because the stock hooks do not fit Tauri:

- The strict JSON check excludes `tsconfig.json` and `tsconfig.*.json`, because those are JSONC (TypeScript allows comments) and the stock hook is strict-JSON-only. Tauri's own JSON configs (`tauri.conf.json`, `capabilities/*.json`) are strict JSON and stay in scope.
- The Rust hooks are local rather than hosted, for the `src-tauri/` manifest-path reason above.

Every such deviation gets a comment explaining why. The next reader needs the reason, not just the rule. A worked example of this config is in this plugin's `reference/tauri-app-pre-commit-config.yaml`.

## Red flags

| Symptom | What it means |
|---|---|
| `Cargo.toml` placed at the repo root | Tauri convention is `src-tauri/`. Tooling will misfire. |
| Hosted Rust pre-commit hooks used as-is | They assume root `Cargo.toml`. Use local hooks with `--manifest-path`. |
| The strict JSON hook is choking on `tsconfig.json` | tsconfig is JSONC. Exclude it, keep Tauri's strict-JSON configs in scope. |
| `tsc` or `vitest` hooks on a vanilla-JS app | Those validators do not apply. Match the hook set to the stack. |
| Real work started before pre-commit was configured | Validators ship from commit one, not added later. |
| A config deviation has no explanatory comment | Document why every deviation exists. |
| App identifier is the bare app name (`superentropy`) rather than reverse-DNS (`industries.nominal.superentropy`) | Use the reverse-DNS form so identifiers do not collide across the portfolio. |
| Repo has only `README.md`, no CLAUDE / HUMANS / PLAN | Four-doc standard not applied. See `nominal-four-doc-standard`. |
| Aesthetic was not picked at scaffold time | App will accumulate visual drift. See `nominal-app-aesthetic`. |

## Rationalizations to reject

- "I will add pre-commit once the app is further along." Validators are the floor and they ship first. Set them up at scaffold time.
- "The hosted Rust hooks are simpler." They assume a root manifest and will not find Tauri's. Local hooks are the correct, not the lazy, choice.
- "Everyone knows why the config is set up this way." The next reader, often a future you, does not. Comment it.
- "Pick the aesthetic after the features work." Picking late produces drift and rework. The aesthetic shapes which features get built and how they surface. Pick at scaffold time, see `nominal-app-aesthetic`.
