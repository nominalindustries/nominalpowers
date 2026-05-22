---
name: nominal-tauri-capabilities
description: Use when wiring `src-tauri/capabilities/*.json` for a Nominal Tauri app, or when debugging a frontend feature that silently does nothing with no console error (drag, click-to-copy, updater relaunch). Covers the recurring landmines: `core:default` and plugin `:default` sets are deliberately conservative, dragging needs an explicit HTML attribute and not CSS, clipboard write is gated separately from read, and adding a plugin to `Cargo.toml` is not enough on its own.
---

# Nominal Tauri Capabilities

## Overview

Tauri 2's capability system is a deny-by-default permission model. Adding a plugin to `Cargo.toml` and the `Builder` chain in `lib.rs` is necessary but not sufficient: the frontend's IPC call into that plugin still bounces off the capability file unless the relevant permission is listed.

The defaults (`core:default`, `<plugin>:default`) are conservative. They include the safe surface, not the full plugin. When a feature "just doesn't work" with no console error, capabilities are almost always the suspect.

This skill is the landmine map. Each entry is a thing we got bitten by on at least one Nominal Tauri app and would rather not get bitten by again.

## When this triggers

- Scaffolding `src-tauri/capabilities/default.json` for a new Nominal Tauri app.
- A frontend feature silently fails with no console error (drag, click-to-copy, file write, updater relaunch).
- Adding a new Tauri plugin and the frontend IPC binding cannot reach it.

## The landmines

### Window dragging

`core:default` does NOT include `core:window:allow-start-dragging`. Without it, *any* drag mechanism (CSS `-webkit-app-region` or the `data-tauri-drag-region` attribute) silently no-ops.

For full window drag in a Nominal Tauri app, list both of these:

```json
"core:window:allow-start-dragging",
"core:window:allow-start-resize-dragging"
```

Once the capabilities are in place, drag the window via the **`data-tauri-drag-region`** attribute on a visible element (typically a `<header>`). Do not use CSS `-webkit-app-region: drag`. The CSS approach is unreliable across platforms in Tauri 2; the attribute is the documented Tauri 2 pattern and is what every Nominal Tauri app that ships should be using.

```html
<header data-tauri-drag-region="">
  <span class="wordmark">SUPERENTROPY</span>
  <!-- interactive children (buttons, links, inputs) work normally inside -->
</header>
```

### Clipboard

`clipboard-manager:default` does NOT include the write or read permissions. If the frontend calls `writeText()` (click-to-copy, auto-copy on generate) it will silently fail without these:

```json
"clipboard-manager:default",
"clipboard-manager:allow-write-text",
"clipboard-manager:allow-read-text"
```

Read is needed for any "still owns it" guard: re-reading the clipboard before auto-clearing to confirm our text is still there. If you only write and never read back, the read permission is optional.

### Updater wants the process plugin too

The updater plugin downloads and verifies the new artifact, but the *relaunch* after installation goes through `tauri-plugin-process`. Adding the updater alone leaves the relaunch silently broken: the user clicks Install Update, the app exits, and nothing comes back.

For a working updater path:

```json
"updater:default",
"process:default"
```

Both plugins also need to be added to `Cargo.toml` and the `Builder` chain.

### Plugin `:default` is the safe subset, not the whole plugin

General principle, not just the three examples above. Every Tauri plugin ships a `:default` permission, but `:default` is a conservative subset of what the plugin can do. When you add a plugin to `Cargo.toml` and to the `Builder` chain, list its `:default` permission in the capability file **and** the explicit permissions for whatever functionality you actually call.

For the Nominal-standard plugin set (clipboard manager, store, window state, log, updater, process):

```json
"core:default",
"core:window:allow-start-dragging",
"core:window:allow-start-resize-dragging",
"clipboard-manager:default",
"clipboard-manager:allow-write-text",
"clipboard-manager:allow-read-text",
"store:default",
"window-state:default",
"log:default",
"updater:default",
"process:default"
```

Adjust per app: a menu-bar utility may not need clipboard, a file-management app may need `fs:` permissions in addition. The principle is constant, the list is per-app.

### Capability files are strict JSON, not JSONC

No trailing commas, no comments. The strict-JSON pre-commit hook in the Nominal scaffold catches this; the typical mistake is pasting an example with a trailing comma from the Tauri docs and watching the hook fail. The fix is to remove the comma, not to weaken the hook.

## How to debug a silent failure

When a frontend feature does nothing and emits no error:

1. Check the browser devtools console **and** the Rust log output (`RUST_LOG=debug npm run tauri dev`). Capability denials are silent on the JS side but logged on the Rust side.
2. Check `src-tauri/capabilities/default.json` for the permission corresponding to the IPC command.
3. Cross-check against the plugin's `permissions/` directory in its crate source (or the Tauri docs page for that plugin) for which permissions exist and what each one gates.
4. After editing the capability file, stop and restart `tauri dev`. Hot reload does **not** pick up capability changes.

## Red flags

| Symptom | What it means |
|---|---|
| Drag does nothing despite `data-tauri-drag-region` on a visible header | Missing `core:window:allow-start-dragging`. |
| Click-to-copy returns no error but the clipboard is unchanged | Missing `clipboard-manager:allow-write-text`. |
| Updater downloads and verifies but never relaunches | Missing `process:default` (the updater calls into the process plugin to relaunch). |
| Drag handle implemented with CSS `-webkit-app-region` | Use the `data-tauri-drag-region` attribute instead. CSS approach is unreliable in Tauri 2. |
| New plugin added to `Cargo.toml` and `Builder`, frontend IPC throws "not allowed" | Plugin permissions not listed in the capability file yet. |
| Capability edit not taking effect | Hot reload does not cover capability changes. Restart `tauri dev`. |
| Strict-JSON pre-commit hook fails on a capability file | Trailing comma or comment pasted from a docs example. Remove it, do not weaken the hook. |

## Rationalizations to reject

- "The plugin's `:default` should cover everything I need." It does not. Plugins ship a conservative default deliberately. List every permission your app actually uses.
- "CSS `-webkit-app-region` works in Chrome, so it should work here." Tauri 2's platform-specific webviews treat that property differently. The `data-tauri-drag-region` attribute is the documented cross-platform answer.
- "Capability changes pick up via hot reload." They do not. The capability file is read at app startup; restart `tauri dev` after editing it.
- "I will add permissions when something breaks." Capabilities are the floor: list them when you wire the plugin, before the silent failures start. Debugging a silent failure costs an order of magnitude more than reading the permissions list once at wiring time.
