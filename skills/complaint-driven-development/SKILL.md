---
name: complaint-driven-development
description: Use when your human partner is complaining about an app, tool, or workflow - one that exists and annoys them, or one they wish existed. The complaint is the design input. Turns gripes into feature specs, brainstorm style, without jumping to code.
---

# Complaint-Driven Development

## Overview

Complaint-driven development is the Nominal intake style. Your human partner complains about an app that exists and irritates them, or one they wish existed, and the complaint is the raw design material. A complaint is a real signal: it is a pain point with the emotion still attached, which means it is honest about what actually matters.

The job is to turn the gripe into a feature spec. This is brainstorming, not building. No code yet.

## When this triggers

Fires when your human partner is complaining in a product-adjacent way: "X is so annoying because...", "why does no app just...", "I wish there were a thing that...", "tool Y makes me do Z and I hate it". The tell is a frustration aimed at software or a workflow gap.

## How to run CDD

1. **Treat the complaint as a requirement in disguise.** "I hate that it makes me do X" is the requirement "must not require X". Translate every gripe into the thing it implies.
2. **Find the root annoyance.** The first complaint is often a symptom. Dig once: what is the actual friction underneath. Several surface gripes frequently share one root.
3. **Brainstorm features, present in chunks.** Turn the requirements into concrete features. Present them in readable chunks your human partner can react to, not one wall.
4. **Push back.** If a complaint implies a feature that fights another goal, or is a complaint about something working as intended, say so. CDD is not a yes-machine, it is a design partnership.
5. **Watch for a new Nominal app.** A rich enough complaint is sometimes not a feature, it is a whole app. Name that when it happens, do not quietly fold a whole product into a feature list.
6. **Stop at the spec.** The output is a feature spec or a design direction, not an implementation. Building starts later, through `writing-plans` and the lead-thread workflow.

## Red flags

| Symptom | What it means |
|---|---|
| You started writing code from a complaint | CDD stops at the spec. Building is a later phase. |
| You took the first complaint at face value | Dig once for the root annoyance underneath. |
| You presented the whole feature set as one wall | Chunk it so your human partner can react. |
| You agreed every complaint implies a good feature | Some complaints fight other goals. Push back. |
| A complaint big enough to be its own app got filed as a feature | Name the app. Do not bury a product. |

## Rationalizations to reject

- "The complaint is vague, I cannot spec from it." The complaint names a pain point. The pain point is the requirement. Extract it.
- "They clearly want this built, I should start." They are complaining, which is intake. Spec first, build later.
- "Every gripe is a feature request." Some gripes are about correct behavior, or conflict with other goals. Evaluate, do not just transcribe.
