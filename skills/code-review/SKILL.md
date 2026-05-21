---
name: code-review
description: Use when reviewing a returned dispatch or having work reviewed, inside the lead-thread workflow. Covers both roles - requesting review of a piece of work and receiving review of it - and the severity grading that decides what blocks progress.
---

# Code Review

## Overview

In the lead-thread workflow, code review is how a returned dispatch becomes integrated work. The lead thread requests review of what a subagent produced, and the work receives it. This skill covers both roles. Review is the stage-two check from `dispatching-subagents`, the quality pass that follows spec compliance.

## When this triggers

Fires when a dispatch returns and the lead thread is reviewing it, and when work is being revised in response to review.

## Requesting and performing review

The reviewer's job is to find what is wrong while the work can still cheaply change.

1. **Spec compliance is already done.** Review here assumes stage one passed, the work did what the dispatch asked. This is the quality pass. If spec compliance was not checked, do that first, see `dispatching-subagents`.
2. **Check against Nominal conventions.** Does it follow the project's patterns, the architecture, the validator expectations. A subagent had no memory of these, so this is where convention drift is caught.
3. **Look for real defects.** Logic errors, missed edge cases, unsafe assumptions, collateral changes to files outside scope.
4. **Severity-grade every finding.** Each issue is graded:
   - **Critical** - wrong behavior, broken build, security or data risk. Blocks integration. Must be fixed.
   - **Major** - a real problem that should be fixed before integration but is not catastrophic.
   - **Minor** - a small improvement, a nit, a polish item. Noted, does not block.
   Grading is what makes review actionable, it separates what stops progress from what does not.
5. **Be specific.** Point at the file and the line, say what is wrong and why. "This could be better" is not a reviewable finding.

## Receiving review

1. **Critical and major findings get fixed.** Not argued away. If a finding is genuinely wrong, say so with reasoning, but the default is fix.
2. **Address findings at the cause.** A fix that papers over a critical finding is not a fix, see `systematic-debugging`.
3. **Re-verify after fixing.** Run the validators again. A fix can introduce a new problem. See `verification-before-completion`.
4. **Do not take it personally and do not get defensive.** Review is the work being improved, not the author being judged. This holds whichever side Claude is on.

## Red flags

| Symptom | What it means |
|---|---|
| Findings have no severity grade | The lead thread cannot tell what blocks integration. Grade them. |
| A critical finding was integrated anyway | Critical blocks. It must be fixed first. |
| A finding said "this could be better" with no specifics | Not actionable. Name the file, line, and the why. |
| Review skipped straight to quality without spec compliance | Stage one first. A well-built wrong thing still fails. |
| A critical finding was masked rather than fixed at the cause | Still broken. Fix the cause. |
| Review was treated as criticism of the author | Review improves the work. Drop the defensiveness. |

## Rationalizations to reject

- "The subagent is good, a light review is enough." Competence is not a substitute for review. A fresh subagent had no project memory.
- "This finding is minor, I will grade it major to be safe." Inflating severity makes grading meaningless. Grade honestly.
- "I will note the issue without a severity." Then the lead thread cannot triage. Every finding gets a grade.
