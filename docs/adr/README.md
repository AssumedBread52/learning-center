# Architecture decision records

A decision record (ADR) is the durable home for a decision and its
reasons. This file is the contract every record follows and carries the
index. The skeleton is `0-template.md`.

## The contract

- **Format.** MADR (Markdown Architectural Decision Records), as laid
  out in the template. Required sections: context and problem statement,
  considered options, decision outcome with consequences and reversal,
  pros and cons of every option. Optional: decision drivers,
  confirmation, more information.
- **Numbering.** The identifier is `ADR-N`, an unpadded integer,
  global across every area, assigned when the record enters the
  repository, in merge order, never reused and never renumbered: prose,
  commit messages, and `supersedes` fields cite it.
- **Naming.** The file is `N-<kebab-title>.md` with the number padded to
  the width of the highest number present; when the count crosses a
  power of ten the files are renamed to the new width and the index
  regenerated, and no identifier changes. The title is a short noun
  phrase naming the chosen option (*PostgreSQL*, *Two mock points*),
  with the problem added only when the option alone would be ambiguous
  (*Per-resource roles*); the decision as a sentence opens the outcome.
- **Every record considers *Do nothing***, meaning keep things as they
  are, and says what that would mean in its context.
- **Records are immutable once merged into `main`.** A changed decision
  is then a new record that supersedes the old one; the old record's
  status becomes *Superseded by ADR-N* and keeps saying why the earlier
  choice was right at the time. Only the status line, `superseded_by`,
  links, and typos may be edited in place. Before the merge anything
  goes: a record is edited freely on its branch, and a branch whose
  decision proves wrong is closed unmerged; the next record to enter
  takes the number.
- **Statuses.** *Implementing*: the feature branch that added the record
  is implementing it. *Implemented*: the work the record calls for is
  complete, set by the last commit on its branch. *Superseded by
  ADR-N*. Nothing else.
- **Lifecycle.** A feature branch begins with the commit that adds its
  record at *Implementing*, carries the commits that implement it, and
  flips the status to *Implemented* in the commit after the last of
  them. A transition record follows the same lifecycle and names its
  trigger as *observed* (a symptom the code or its operation produced)
  or *deliberate* (a learning exercise simulating a pressure the project
  lacks, earned by simulation on a working application, with its
  reversal cost stated). No tags.
- **Feature-scoped records.** One record per implementation choice that
  has real alternatives, written at slice planning, grouped by `area` in
  the index, never a narrative of how the feature works.
- **Internal forces decide; external sources inspire.** A record is
  raised by forces inside the project, its drivers and measured needs,
  and its choice rests on them. Sources outside it, earlier attempts
  included, may only suggest options: an artifact carried over enters as
  one option among at least two, re-derived from measured needs, and
  prior use is never the reason it is chosen.
- **Reversal cost and dependents are stated** in every record, because
  no decision is locked: some are heavy, none are final.
- **Areas.** `process`, `repository`, `toolchain`, `stack`, `testing`,
  `operations`, `architecture`, `security`, `front-end`, `domain`,
  `product`, or a feature name.
- **Width.** Prose wraps at 80 columns, the width code follows, so one
  editor ruler serves both. Heading lines, the front-matter title, table
  rows, and URLs are exempt, since they cannot wrap.
- **Validation.** The index below is maintained by hand in the shape
  shown, one row per record in number order, until a validator in the
  build gate checks every record against this contract and regenerates
  the index from front matter.

## Index

| Number | Title | Area | Status |
|---|---|---|---|
| [1](1-madr-records.md) | MADR records | process | Implementing |
