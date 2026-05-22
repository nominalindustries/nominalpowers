---
name: nominal-updater-pipeline
description: Use when wiring the update and distribution path for a Nominal Tauri app, or when debugging the deploy script. Covers the `scripts/deploy-update.sh` shape, the `site/<app>/` release-notes mini-site, the R2 + Cloudflare Worker chain, the minisign signing key ritual, and the per-app subdirectory layout that prevents apps from stepping on each other's distribution assets.
---

# Nominal Updater Pipeline

## Overview

Every Nominal Tauri app self-updates from `updates.nominalindustries.com/<app>/`. The chain has three parts:

1. **Build + sign** locally via `cargo tauri build` plus the minisign signing key.
2. **Upload** the artifacts and the release-notes mini-site to a shared Cloudflare R2 bucket (`nom-packages`).
3. **Distribute** via a Cloudflare Worker fronting R2, with optional cache purge.

The whole chain is driven by `scripts/deploy-update.sh` in each app's repo. The script is **adapted, not shared**, across apps: each app owns a copy so a bugfix in one does not silently desync the others. If you find yourself improving one app's script, port the change deliberately.

This skill is the chain map.

## When this triggers

- Scaffolding the deploy path for a new Nominal Tauri app, typically before the first v0.x release.
- Debugging an existing app's deploy (failed upload, missing artifact, updater not picking up the new version).
- Adding a new app to the cross-app registry.

## Repo layout

Each Nominal Tauri app carries:

```
scripts/
  deploy-update.sh        executable bash, drives the whole publish
site/
  <app>/
    index.html            release-notes page, fetches versions.json client-side
    versions.json         version history (script appends to this on each deploy)
    icon.png              80x80 display copy; sourced from src-tauri/icons/icon.png
```

The R2 bucket (`nom-packages`) is shared across apps. Each app owns its subdirectory (`/superentropy/`, `/nibble/`, etc.). The bucket *root* holds an `index.html` and `apps.json` that list every Nominal app; the per-app `site/` deliberately does NOT include those root files. If an app's deploy script uploaded them, it would overwrite whatever the other apps put there.

Adding a new app to the cross-app listing is a one-time edit to a central `apps.json` (currently maintained in Nibble's `site/`; eventually a separate registry repo).

## Signing key ritual

Each app has its own minisign keypair, not shared:

1. Generate once: `npx @tauri-apps/cli signer generate -w ~/.tauri/<app>.key`.
2. The private key file (`~/.tauri/<app>.key`) is gitignored. The password lives in `.envrc-secrets`.
3. The corresponding public key goes into `src-tauri/tauri.conf.json` under `plugins.updater.pubkey`.

The signing env vars in `.envrc-secrets`:

```bash
export TAURI_SIGNING_PRIVATE_KEY_PATH=~/.tauri/<app>.key
export TAURI_SIGNING_PRIVATE_KEY_PASSWORD="..."

# Apple Developer signing identity, optional but required for notarized DMG
export APPLE_SIGNING_IDENTITY="Developer ID Application: <Name> (<TeamID>)"

# Cloudflare Worker cache purge secret, optional but speeds up update propagation
export PURGE_SECRET="..."
```

Replacing or rotating the private key requires shipping an app version that knows about the new pubkey; users on the old pubkey will reject the new signature.

## The deploy script

```bash
./scripts/deploy-update.sh \
  --notes "First note; Second note; Third note" \
  [--codename "Shannon"]            # optional; releases get a codename per app theme
  [--skip-build]                    # skip cargo+tauri build, reuse existing artifacts
  [--site-only]                     # only push site/ assets (release notes + icon), no build
```

What it does, step by step:

1. **Resolves the signing key** from the env var (`TAURI_SIGNING_PRIVATE_KEY_PATH` or `TAURI_SIGNING_PRIVATE_KEY` inline).
2. **Runs `npm run tauri build`**, producing `.app.tar.gz` + `.sig` + `.dmg` under `src-tauri/target/release/bundle/`.
3. **Reads the version** from `src-tauri/tauri.conf.json`.
4. **Generates `latest.json`** keyed for `darwin-aarch64` and `darwin-x86_64` (same artifact + signature for both, since universal binary).
5. **Appends or replaces** the version entry in `site/<app>/versions.json`, with `--notes` parsed as a semicolon-separated list. Uses Python (not bash string ops) for the JSON mutation so the operation is safe and atomic.
6. **Uploads to R2** via `wrangler`: artifact, .sig, latest.json, dmg (with the `rw.NNN.` temp prefix normalized away), plus every file under `site/<app>/`.
7. **Optionally POSTs** to `updates.nominalindustries.com/_purge` with `X-Purge-Secret` to clear the Worker cache.

Required tooling:

- `wrangler login` (Cloudflare CLI authenticated).
- `python3` on PATH for the safe versions.json mutation.

## Endpoints once deployed

- **Updater check:** `updates.nominalindustries.com/<app>/latest.json` (CF Worker fronts R2).
- **DMG / tarball direct download:** `packages.nominalindustries.com/<app>/...`.
- **Release notes page:** `updates.nominalindustries.com/<app>/` (renders `versions.json` client-side).

## Codename theme

Each app picks a codename theme for its releases. Nibble uses pastries (Cruller, Rainbow Sprinkles). SuperEntropy uses cryptographers (Shannon for v0.5.0). The codename is optional per release; an app can ship with `codename: null` if no theme is picked yet.

Themes shape the voice over time: a Shannon release feels different from a Diffie release feels different from a Hellman release, and the cumulative effect gives the app a personality across versions.

## Cross-app coordination

The single shared resource is the R2 bucket. Each app owns its subdirectory; nothing reaches across.

- ✅ `site/superentropy/index.html` → `nom-packages/superentropy/index.html` (this app's deploy)
- ✅ `site/superentropy/versions.json` → `nom-packages/superentropy/versions.json` (this app's deploy)
- ❌ `site/apps.json` (would overwrite the cross-app registry)
- ❌ `site/index.html` (would overwrite the bucket-root landing page)

When adding a new app to the cross-app listing, the edit goes to the central registry, not to the new app's `site/`.

## Red flags

| Symptom | What it means |
|---|---|
| `scripts/deploy-update.sh` references a hardcoded app name or path from another app | Adapted-not-shared discipline broken. The script gets copied between apps, but the slug, identifier, and key paths are per-app. |
| `site/` directory contains `index.html` or `apps.json` at the root, not under `<app>/` | Would overwrite the cross-app registry on upload. Move under the app's subdirectory or delete. |
| Updater downloads but rejects the signature | Pubkey in `tauri.conf.json` does not match the signing key in `~/.tauri/<app>.key`. Regenerate one or align the other. |
| New version uploaded but updater still serves the old `latest.json` | Worker cache. Either set `PURGE_SECRET` and let the script purge, or wait for TTL. |
| `wrangler` upload fails with auth error | `wrangler login` not run, or the account does not own the bucket. |
| `versions.json` corrupted after a deploy | Bash JSON mutation. The script must use Python (or `jq`) for the mutation; raw bash string ops eventually break. |
| Two apps' deploys race and one overwrites the other's bucket-root files | Bucket-root files (`index.html`, `apps.json`) should never be uploaded by an app's deploy script. Only per-app subdirectory writes. |

## Rationalizations to reject

- "Share one deploy script across all apps." Tempting but produces silent desync when one app needs a tweak. Adapted-not-shared: each app owns a copy, port changes deliberately.
- "We can put the bucket-root files in this app's `site/` for convenience." That convenience is exactly the bug. Bucket-root files live in a central registry, not in any single app's deploy.
- "The minisign key can be shared across apps." It cannot. Each app has its own keypair so a leak in one does not invalidate the others.
- "Pubkey rotation is fine, users will pick up the new one on next update." Users on the *current* pubkey will reject signatures from the *new* key. Rotation requires shipping a transitional version that knows about both.
- "Cache purge is optional, skip it." If you skip it, expect users to see the old version for the TTL window. Set `PURGE_SECRET` and let the script purge.
