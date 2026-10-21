---
title: Short noun phrase naming the chosen option
status: Implementing
date: 2026-01-01
area: process
trigger: none
supersedes: none
superseded_by: none
---

# ADR-N: Short noun phrase naming the chosen option

Copy this file to the next free number. Sections marked *required* must be
present with content; sections marked *optional* may be deleted. Delete these
two paragraphs. The front matter fields are all required: `area` is one of the
areas listed in `README.md`, or the feature name for a feature-scoped record;
`trigger` is `observed`, `deliberate`, or `none`; `supersedes` and
`superseded_by` are `ADR-N` or `none`.

Keep the whole record under 150 lines, wrapped at 80 columns (headings, the
front-matter title, table rows, and URLs are exempt), in plain prose. Say what
was decided and why: forces inside the project raise the question and decide it,
and outside sources only suggest options. Never narrate how a feature works.

## Context and problem statement

*Required.* Two to six sentences: the situation, the forces at play, and the
question, stated as a question. Name the slice or feature that raised it when
there is one.

## Decision drivers

*Optional.* Bullets naming what matters most in this choice, in order.

## Considered options

*Required.* A numbered list of options. One of them is always *Do nothing*: keep
things as they are, with one clause saying what that means here.

## Decision outcome

*Required.* "Chosen option: N, *name*, because <one sentence>." Then the
decision itself, in enough detail to implement it and nothing more.

### Consequences

*Required.* Bullets starting *Good:* or *Bad:*.

### Reversal

*Required.* What reversing this would cost, and which records depend on it (by
number) and would reopen.

### Confirmation

*Optional.* How compliance is checked: a lint rule, a test, a hook, a review
step, a build-gate check.

## Pros and cons of the options

*Required.* One subsection per option, in the order listed above, with bullets
starting *Good:* or *Bad:*. The chosen option's subsection may be short when the
outcome already argues it.

### Option 1: name

### Option 2: name

### Option N: Do nothing

## More information

*Optional.* Sources consulted, related records, open points, and for a
transition record the trigger that fired and whether it was observed or
deliberate.
