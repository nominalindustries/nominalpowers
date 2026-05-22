---
name: nominal-app-aesthetic
description: Use when scaffolding a new Nominal Industries app or when an existing app's visual design has drifted. Establishes the discipline that every Nominal app picks a coherent aesthetic spine at scaffold time and treats "aesthetic complete" as a release gate alongside "features complete". Not a fixed palette; the spine is per-app and the discipline is that there *is* one.
---

# Nominal App Aesthetic

## Overview

Each Nominal Industries app has an aesthetic. It does not have to be the same aesthetic as the other apps in the portfolio. The discipline is that there *is* a coherent one, picked deliberately at scaffold time, and treated as part of "done."

This skill exists because incoherent UI is friction, and friction is what kills spicy-brain attention before the feature gets used. The difference between a Nominal app and a 1998 Java applet (or Oracle EBS, source: lived experience) is not the framework. It is that someone picked an aesthetic, wrote it down, and held to it.

An app is not done if the features work but the UI feels assembled from defaults. That state is "engineering complete, aesthetic incomplete," and the second half is not optional.

## When this triggers

- Scaffolding a new Nominal app.
- Reviewing UI changes that introduce a new color, font, or visual pattern not previously in use.
- Preparing for a v1 release where the aesthetic has not been documented in CLAUDE.md.
- An app feels "off" but no specific feature is broken.

## What an aesthetic spine includes

The spine is the small set of visual decisions the rest of the app inherits from. It does not have to be elaborate, only deliberate:

- **Surface treatment.** Light or dark? Warm or cool? How saturated are the surfaces?
- **One primary accent.** The brand color, used consistently for emphasis. Other accents may exist but defer to it.
- **Typography pairing.** One typeface for code, identifiers, monospace content. One typeface for UI chrome. Two faces is the discipline; three is a smell.
- **Motion language.** Snappy or considered? How prominent are state changes (regenerate, load, save)?
- **Density.** How much whitespace? Compact utility or generous canvas?
- **Icon palette.** Drawn from the same colors as the rest of the app. Luminance hierarchy so the icon stays readable at small sizes (dock, favicon, system tray).
- **Voice pairing.** Optional but encouraged: a tagline that pairs the verbal voice with the visual. SuperEntropy's "Cryptographically secure. Theatrically random." tells you what the visual should feel like before you see it.

The spine is per-app. Two Nominal apps with different aesthetic spines are fine. Two Nominal apps with no spines and accidentally similar palettes is not.

## The discipline

1. **Pick the spine at scaffold time.** Not after features ship. The spine shapes the features (a generous-canvas app and a dense-utility app surface the same data differently). Picking it late produces drift and rework.

2. **Write it into CLAUDE.md.** The "Aesthetic direction" section lists the surface treatment, the accent color, the typography pair, the icon palette, and any motion notes. Subagent dispatches inherit it automatically; nothing gets retro-styled.

3. **Cross-check additions against the spine.** A new component, a new color, a new font lands only if it composes with the spine. If it does not, either revise the spine deliberately (and update CLAUDE.md) or reject the addition.

4. **Treat "aesthetic complete" as a release gate.** Alongside "features work" and "tests pass," the question is "does this look like a Nominal app shipped with care." If the answer is no, it is not v1-ready.

## Style rules that ride along

These are Nominal-wide and apply to every app's aesthetic spine regardless of palette:

- **No emdashes or endashes** in user-facing text, App Store descriptions, release notes, or anything the human partner will paste as their own writing. Use commas, parens, or hyphens.
- **No accidental defaults.** A white background, blue links, and Times New Roman are signals that the spine was never picked. Either the spine includes those choices deliberately, or they get replaced.
- **Restrained motion.** A regenerate is a small fade-replace, not a slot machine. Spicy-brain attention is finite; motion spends it.

## Red flags

| Symptom | What it means |
|---|---|
| App ships with default Tauri-generated UI (white bg, default fonts, default links) | Spine was never picked. Pick one before next ship. |
| CLAUDE.md has no "Aesthetic direction" section | Spine is not documented; subagent dispatches will drift. Add it. |
| Three or more typefaces in the app | Pairing discipline broken. Get back to two: monospace for code, UI face for chrome. |
| Two Nominal apps have accidentally similar palettes with no deliberate intent | Either declare them aesthetically siblings on purpose, or differentiate. |
| User-facing text contains emdashes or endashes | Style rule violation. Replace with commas, parens, or hyphens. |
| Icon palette uses colors that do not appear anywhere else in the app | Icon was treated as a separate artifact. Pull the palette back into the spine. |
| "We will polish the UI before ship" with no aesthetic spine documented | Polish without a spine produces drift. Define the spine first, then polish. |

## Rationalizations to reject

- "Aesthetic is subjective, we will iterate." Some aesthetics are objectively incoherent (twelve fonts, accent colors from five different palettes). The discipline is pick-one-and-keep-it, not pick-the-best.
- "The user does not care about visual polish in a utility." The user might not name the polish, but they feel its absence as friction. A utility that looks like Oracle EBS gets used grudgingly, not gladly.
- "We can ship without it and add polish in v1.1." If v1 ships with the wrong aesthetic, v1.1 has to renegotiate it with users who learned the old shape. Cheaper to get it right at v1.
- "The framework's default looks fine." The framework's default is designed to be inoffensive, not to be a Nominal app. Inoffensive is not enough.
