---
name: nominal-four-doc-standard
description: Use when scaffolding a new Nominal Industries repo, or when an existing repo's documentation has drifted from the standard. Covers the four-doc layout (README, CLAUDE, HUMANS, PLAN), the ambient-state pattern (`notes/STREAM.md`), the invariants-ladder convention at the top of CLAUDE.md, and the granularity split between PLAN and STREAM.
---

# Nominal Four-Doc Standard

## Overview

Every Nominal Industries repo carries four documentation files plus an ambient-state file. Each has a defined author of record and a defined audience. The split exists because Nominal repos are built primarily by Claude with the human partner providing direction, and a traditional README-only setup does not capture that collaboration model.

This skill is the doc scaffold. The four docs and the STREAM file go in before real work starts, not bolted on later.

## When this triggers

- Scaffolding a new Nominal repo.
- An existing repo has only a README and is missing CLAUDE / HUMANS / PLAN.
- CLAUDE.md exists but has no invariants section, or the invariants are scattered through prose instead of named and numbered.
- PLAN.md and STREAM.md have drifted (PLAN at epic level, STREAM at task level, or vice versa).

## The four-doc table

| File | Author of record | Audience | Purpose |
|------|------------------|----------|---------|
| `README.md` | Shared | Everyone | Public-facing project overview. What it is, how to use it. |
| `CLAUDE.md` | Human partner (for Claude) | Claude | Project context, architecture, conventions, invariants. The "here is what you need to know" file. |
| `HUMANS.md` | Claude (for the human partner) | Human partner + contributors | Setup, working model, the "why" alongside the "what". The flipped CLAUDE.md, fair is fair. |
| `PLAN.md` | Shared | Both | Living task tracker. Phase tracking, session log, the shared brain between sessions. |

The split is non-symmetrical: CLAUDE.md is written *for* Claude (audience) but *by* the human partner (author). HUMANS.md is the inverse. PLAN.md is shared territory. The audience-author split is what makes each file useful for its actual reader.

## The fifth document: notes/STREAM.md

Beyond the four root docs, every repo carries `notes/STREAM.md`: the ambient-state file.

Sections it includes:

- **Active threads** - what is currently in play, at the human partner's natural granularity (epic-level by neurotypical standards).
- **When we come back (don't get lost)** - cold-pickup instructions when the session resumes after time away.
- **Recently resolved** - decisions and milestones from the recent past, dated.
- **Waiting** - what is blocked on the human partner.
- **Blocked** - what is blocked on external dependencies (vendor, account, hardware).
- **Scratch** - working notes that do not belong in PLAN.md.

STREAM.md lives in `<repo>/notes/`, not in `~/streams/` or any other out-of-repo location. It travels with the repo so a fresh checkout includes the ambient context.

## The invariants ladder

CLAUDE.md carries a numbered list of 3-5 non-negotiable invariants near the top. Each invariant is a sentence or two; together they are the project's load-bearing constraints. Any future request that would violate one gets pushed back on before work starts.

Example (from SuperEntropy's CLAUDE.md):

> 1. **OS CSPRNG is always the primary entropy source.** Every "entropy source" the user toggles is additional salt mixed in via XOR, never a replacement.
> 2. **No secret-bearing data structure outlives the function that generated it.** No password history. No clipboard log. No telemetry.
> 3. **Reusable primitives extract to `nominal-sdks-rust` crates.** The app is a thin shell.
> 4. **v1 ships without:** network entropy sources enabled by default, SDR support, webcam noise, sync, history, vault features.
> 5. **No emdashes or endashes** in user-facing text or in anything the human partner will paste as their own.

The invariants shape every architectural decision. Writing them down at scaffold time is what makes them enforceable.

## Granularity split: PLAN vs STREAM

PLAN.md items are at neurotypical granularity, small enough that a neurotypical PM would recognize them as tasks. Each item has a definite-of-done. Example: "Phase 2.d: presets, auto-copy, clipboard auto-clear, persistence" is a PLAN.md item.

STREAM.md items are at the human partner's natural granularity (epics by neurotypical standards). Each item is a thread, not a task. Example: "Ship v0.5.0" is a STREAM.md thread; the 5 tasks under it (build, sign, publish, etc.) live in PLAN.md under that release plan.

Mixing them produces dysfunction:

- Epics in PLAN.md never get checked off and demoralize the tracker.
- Tasks in STREAM.md crowd out the ambient context.

When in doubt: if it would take less than a day, it is a PLAN item. If it would take a week or more, or never quite finishes, it is a STREAM thread.

## Red flags

| Symptom | What it means |
|---|---|
| Repo has only README.md | Missing CLAUDE / HUMANS / PLAN. Scaffold the four-doc standard. |
| CLAUDE.md has no invariants section | The constraints are not enforceable. Write 3-5 numbered invariants near the top. |
| STREAM.md lives outside the repo (e.g., `~/streams/`) | Move it to `<repo>/notes/STREAM.md` so it travels with the repo. |
| PLAN.md is full of week-long epics | Granularity mismatch. Move epics to STREAM.md, break each epic into PLAN tasks. |
| STREAM.md is full of one-day tasks | Inverse granularity mismatch. Move tasks to PLAN.md. |
| HUMANS.md does not exist | The "how to work with Claude on this repo" model is not documented. Claude writes it. |
| Invariants written into CLAUDE.md as prose, not numbered | Easy to overlook on a quick read. Number them. |

## Rationalizations to reject

- "A README is enough for a small repo." The four-doc standard exists because *every* Nominal repo benefits from the audience-author split, regardless of size. Smaller repos get smaller docs, not fewer.
- "I will write CLAUDE.md once the architecture stabilizes." The architecture stabilizes *because* the invariants exist. Backwards order produces designs that violate the invariants once they are written.
- "HUMANS.md is redundant if the human partner already knows the repo." It is for *future* humans (and future-you) picking it up cold. Write it for them.
- "STREAM.md is just a journal." It is a journal with structure. The structure (active / when-we-come-back / blocked / scratch) is what makes a cold pickup possible.
