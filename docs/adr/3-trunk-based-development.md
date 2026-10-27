---
title: Trunk-based development
status: Implementing
date: 2026-10-03
area: process
trigger: none
supersedes: none
superseded_by: none
---

# ADR-3: Trunk-based development

## Context and problem statement

Production runs whatever `main` holds. One person reviews every change, so a
change is only as safe as it is small enough to read: a feature landing as a
hundred changed files has been dumped, not delivered. The commit history is
meant to show where each decision was made and how its work arrived. How should
changes travel from the working tree to `main`, and what must be true of every
commit on the way?

## Decision drivers

- *Reviewability:* every change is gone over personally, in small pieces.
- *A safe production branch:* production can take `main` at any commit.
- *The history as a record:* granularity is kept; nothing rewrites it.

## Considered options

1. *Trunk-based with releasable commits and merge commits.* `main` is
   production; short-lived feature branches; every commit could ship; pull
   requests group commits and land as merge commits.
2. *The same, with squash merges*: one commit per pull request on `main`.
3. *A release-candidate branch promoted on a cadence*: a candidate branch
   becomes production every two weeks or so.
4. *Do nothing*: commit straight to `main` with no branches, pull requests, or
   releasability requirement.

## Decision outcome

Chosen option: 1, *trunk-based with releasable commits and merge commits*,
because it keeps `main` deployable at every commit, keeps each change small
enough to review, and preserves the granularity that makes the history a record.

- *The branch flow.* `main` is the production branch; branch off it for a
  feature or fix; commit in small increments; open a pull request to `main`;
  once approved, merge; production pulls the change. Branches are short-lived;
  `main` changes only by merging pull requests, and branch protection forbids
  direct pushes.
- *Every commit is releasable.* It builds, its tests pass, and it could be
  deployed. Not every commit is released: branches and pull requests group
  commits into units of work. Releasable means safe to ship, not shipped.
- *Merge commits, never squash.* Squashing throws the granularity away;
  rebase-and-merge would keep it, but a merge commit also leaves each pull
  request a commit of its own in the log.
- *One record per branch.* A branch is named for the record it adds (`ADR-3`)
  and carries that record and only what it needs; every commit header begins
  with the identifier, `ADR-3: adopt trunk-based development`, so
  `git log --grep` finds a decision's whole trail. Work with no record is
  settled when the first such change comes up.
- *Soft size targets.* A commit touches roughly one concern; a pull request
  stays within a few hundred changed lines where possible, past which review
  catches fewer defects. Size is controlled before building: releasable slices
  are agreed first, since splitting afterwards is damage control.
- *Releasability has techniques.* Schema changes use expand-and-contract, each
  step its own commit; incomplete work lands hidden until it is whole.
- *What the repository carries for it.* A pull-request template asking for the
  two things a diff cannot show, why and what was verified, and a versioned
  `commit-msg` hook checking every header.

### Consequences

- *Good:* deployment needs no release step, since `main` is releasable by
  requirement.
- *Good:* the commits that mark a decision are never rewritten or
  collapsed.
- *Bad:* every intermediate commit must build and pass, so incomplete work needs
  a way to stay hidden, and a schema change takes several commits instead of
  one.

### Reversal

Low mechanically: the merge strategy is a repository setting, and a candidate
branch can be added later as a deliberate exercise with its reversal cost
stated. Dropping releasability is heavier: deployment from `main`, a
commit-level gate, and hidden incomplete work all assume it. Builds on ADR-2,
whose branches, pull requests, and protection it uses; reopens ADR-1, whose
history marks it keeps.

### Confirmation

Branch protection on `main` requires a pull request, forbids direct pushes, and
allows merge commits only. The `commit-msg` hook in `.githooks/` rejects any
message that is not one header line of `ADR-N: ` and a description without a
final period, within 72 columns so that `git log` and GitHub show it whole at
80; bodies and footers are rejected until the hook checks them.

## Pros and cons of the options

### Option 1: Trunk-based with releasable commits and merge commits

- *Good:* argued above; the simplest flow with both a gate and a mark.
- *Bad:* the discipline costs hidden work and multi-step schema changes.

### Option 2: The same, with squash merges

- *Good:* one commit per pull request and a tidy linear log.
- *Bad:* throws away the granularity that is the point; a decision's own commit
  vanishes into the squash.

### Option 3: A release-candidate branch promoted on a cadence

- *Good:* batches changes for a scheduled release with a last check before
  production.
- *Bad:* it coordinates teams and a release calendar this project lacks, delays
  production by up to a cycle, and simulates a pressure the project does not
  face.

### Option 4: Do nothing

- *Good:* no branches, no pull requests, no ceremony.
- *Bad:* knowingly broken commits can land, nothing groups work, and with
  production taking `main`, a broken commit is a broken deployment.

## More information

Sources: the brainstorming notes (*Commits, review, and releasability*, and the
agreements on releasable commits, trunk-based development, merge commits, and
soft size targets). The branch flow dates from 2026-10-03; record-named branches
and headers replaced Conventional Commits on 2026-10-20.
