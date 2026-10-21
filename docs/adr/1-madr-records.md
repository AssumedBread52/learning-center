---
title: MADR records
status: Implementing
date: 2026-10-03
area: process
trigger: none
supersedes: none
superseded_by: none
---

# ADR-1: MADR records

## Context and problem statement

Decisions are made continually, and the reasons behind them fade faster than the
code they shape. Two principles set the requirements: the commit history should
show where each decision and transition happened, and no decision is locked, so
each must state its reversal cost. A record that is edited in place, or never
written, leaves a reader with the current code and no way to tell a deliberate
choice from an accident. How should decisions be recorded so that records stay
true, keep their reasons, and mark history?

## Decision drivers

- *The history shows the change.* A reader of the log finds the commit where a
  decision was made or changed.
- *The reason survives the reversal.* Why a choice was right at the time is the
  hardest part to reconstruct later.
- *Reversal cost is visible, and the contract is enforced.* Decisions are doors,
  some heavy and none locked; a convention nobody checks decays.

## Considered options

1. *MADR records, immutable, superseded by new records.*
2. *Mutable records edited in place*, moving the status line when a decision
   changes: the developer's first instinct.
3. *Nygard's short format* (added for completeness): context, decision, status,
   consequences, with no section for alternatives.
4. *Do nothing*: no records; reasons stay in conversations, notes, and commit
   messages.

## Decision outcome

Chosen option: 1, *MADR records, immutable, superseded*, because a new record is
itself the mark in the history and the old record keeps saying why the earlier
choice was right at the time.

- *Format.* MADR, as laid out in `docs/adr/0-template.md`: context, considered
  options, outcome with consequences and reversal, pros and cons of every
  option. Every record is raised by forces inside the project, outside sources
  only suggesting options; considers *Do nothing* and says what it means in its
  context; states its reversal cost; and names its dependents by number, since a
  changed decision may reopen others (adopting GraphQL would reopen the choice
  of schema contracts).
- *What gets a record.* Every exception to a standard and every tool choice,
  exceptions genuinely avoided first; a vendor's container image taken in place
  of a project-built one is the typical case. Feature records: one per
  implementation choice with real alternatives, written at slice planning,
  grouped by feature in the index, never a narrative of how the feature works.
  An artifact carried over from elsewhere enters as one option among at least
  two, re-derived from measured needs; prior use is evidence, never a default.
- *Naming.* The identifier `ADR-N` is an unpadded integer assigned when the
  record enters the repository, never reused or renumbered; the file name pads
  it to the width of the highest number and is renamed at a power of ten; the
  title is a short noun phrase naming the option.
- *Lifecycle.* Statuses *Implementing*, *Implemented*, and *Superseded by
  ADR-N*. Once merged, a changed decision is a new record that supersedes the
  old, and only the status line, `superseded_by`, links, and typos change in
  place; before the merge a branch is edited or closed freely. A branch begins
  with the commit that adds its record at *Implementing* and ends with the one
  that sets *Implemented*; no tags, the status line doing what a tag would.
- *Agreements become decisions or conventions.* A record when the agreement
  chooses an architecture, a tool, or an exception with alternatives worth
  recording; otherwise a convention, linted if it can.
- *Tooling.* The template and the contract with its index in
  `docs/adr/README.md` enter with this record; the template marks required and
  optional sections, so a change in expectations is one diff to one file. The
  build-gate validator, which regenerates the index, and the pull-request
  template enter with their own records. A procedure for adding a record,
  extracted after two or three are written by hand, cites the contract as its
  definition of done.

### Consequences

- *Good:* the current decision per topic is one lookup away in the index, and
  the chain behind it reads in order.
- *Good:* the self-describing page can render the records with their statuses,
  so a stale record shows on screen.
- *Bad:* a decision costs at least two options and a stated reversal, more
  ceremony than a note in a commit message.

### Reversal

Low for the format: records are prose and converting them is mechanical. Higher
for immutability: editing in place would lose the history marks later records
rely on. Every later record follows this contract; the build-gate validator's
record depends on it and would reopen.

### Confirmation

A record is accepted when its pull request merges into `main`; a branch that is
closed unmerged accepts nothing. Until a validator joins the build gate, that
review checks each record against the contract in `docs/adr/README.md` and keeps
the index by hand; afterwards the validator checks every record and regenerates
the index.

## Pros and cons of the options

### Option 1: MADR records, immutable, superseded

- *Good:* the required options section forces *Do nothing*, gives a carried-over
  artifact a place as one option among several, and lets a validator check
  sections, front matter, and supersession links.
- *Bad:* the longest of the four formats, so each record asks more of its
  reader's attention.

### Option 2: Mutable records edited in place

- *Good:* one file per topic, always current, no chain to follow.
- *Bad:* the edit hides where the change happened and overwrites the old
  reasons; once editing stops nothing marks a record stale, so it goes on
  arguing for a choice the code has abandoned.

### Option 3: Nygard's short format (added for completeness)

- *Good:* the shortest to write, and the original form of the practice.
- *Bad:* no required section for alternatives or reversal, so the contract's two
  load-bearing requirements would be conventions rather than structure a
  validator can check.

### Option 4: Do nothing

- *Good:* no ceremony at all.
- *Bad:* a conversation is not durable and a commit message is too short for
  options and reversal, so the reasons would have no home.

## More information

Sources: the brainstorming notes (*Evolutionary architecture* and the agreements
log). Agreed 2026-10-03; feature records, carried-over artifacts, and the
tooling on 2026-10-09; the tooling's separate records on 2026-10-14; internal
forces deciding, outside sources inspiring, on 2026-10-20.
