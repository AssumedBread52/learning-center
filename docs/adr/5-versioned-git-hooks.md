---
title: Versioned git hooks
status: Implemented
date: 2026-10-29
area: process
trigger: none
supersedes: none
superseded_by: none
---

# ADR-5: Versioned git hooks

## Context and problem statement

Every commit is meant to be releasable, and every record to follow its
contract, but stated alone those are habits, and a habit fails exactly
when attention is elsewhere. A check that runs after the commit exists
finds the breakage once it is already history. The repository already
carries one check at commit time, the header check, without a decision on
how such checks are delivered. How do checks run on every commit, before
it exists, with nothing installed on the host?

## Decision drivers

- *Before the commit exists*, so a broken commit is never written.
- *Nothing installed on the host*: the hook runs on the host, so it may
  use only what the host already has.
- *A fresh clone has it* after the bootstrap script, with no extra step.
- *Fast enough never to be worth skipping.*

## Considered options

1. *Plain scripts in a versioned `.githooks/`*, reached through
   `core.hooksPath`.
2. *A hook manager* (Husky, Lefthook, or the `pre-commit` framework).
3. *Checks only after the commit*, in a `pre-push` hook or a hosted
   service.
4. *Do nothing:* the header hook stays as it is, and everything else is
   checked by habit.

## Decision outcome

Chosen option: 1, *plain scripts in a versioned `.githooks/`*, because it
is the only option that runs before the commit while installing nothing.

- *Where hooks live.* Each hook is a bash script in `.githooks/`;
  `scripts/up.sh` sets `core.hooksPath` to the directory, so a clone has
  every hook once it has been brought up.
- *What a script on the host may use:* bash, git, docker, and the POSIX
  utilities with their POSIX options only, so the scripts run wherever
  those exist; anything else runs in a container.
- *`commit-msg`* checks the header against the commit rules.
- *`pre-commit`* runs every script in `scripts/checks/` in name order,
  reports every one that fails, and refuses the commit if any did. Each
  check decides where it runs, on the host or through `docker compose
  run`. The first checks are the record validator, run on the working
  tree's `docs/adr`, and the image check: no `Dockerfile`, `*.Dockerfile`,
  or `Containerfile` among the files git tracks, and at least one image,
  each image that `docker compose --profile '*' config --images` resolves
  with placeholder user ids, named by a `MAJOR.MINOR.PATCH` tag and nothing
  else. Every profile, because a profiled service is otherwise skipped; an
  image that needs another form gets an inline exception when it arrives.
  Their tests sit beside them as checks too, so a failing test refuses a
  commit like any other failure.
- *Adding a check needs no record of its own:* it is a file in
  `scripts/checks/`, and the hook never changes. A record that brings a
  tool adds the tool's check on its own branch; a check using tools already
  decided is an ordinary commit.
- *A time budget.* The hook stays fast enough that skipping it is never
  tempting; its number is set once there is a test suite to measure, and
  until then review watches the hook's duration.
- *Skipping is a person's decision.* `git commit --no-verify` is taken by
  hand, never by tooling, and a commit that needs it is not releasable.

### Consequences

- *Good:* releasability and the record contract are enforced at the
  moment of commit, and a fresh clone has the hooks after one script.
- *Good:* a hook is a file in the repository, reviewed like any other.
- *Bad:* every commit waits for its checks, one to two seconds for each
  that runs in a container; checks on the host and batched container
  starts are the first remedies when the budget tightens.
- *Bad:* hooks run on the client: `--no-verify`, a clone never brought up,
  and a commit made elsewhere all skip them, which a hosted check closes.

### Reversal

Cheap mechanically: delete the scripts and unset `core.hooksPath`. Costly
in what rests on it: ADR-3's header rule and ADR-4's image check lose
their enforcement and become review items again. Builds on ADR-4, whose
containers run the checks that need tools and whose bootstrap script sets
the hooks path.

### Confirmation

The hooks confirm themselves: a commit whose header or fast check fails is
refused, and the refusal names the failing check. Whether a script keeps to
POSIX utilities and options is a review item, since no check sees it.

## Pros and cons of the options

### Option 1: Plain scripts in a versioned `.githooks/`

Argued in the outcome. *Bad:* bash, with no framework conveniences such
as running checks only on staged files.

### Option 2: A hook manager

- *Good:* conveniences such as staged-file filtering and parallel steps.
- *Bad:* each is installed on the host, through npm, a binary, or pip,
  since git runs hooks there; that is the installing ADR-4 forbids.

### Option 3: Checks only after the commit

- *Good:* nothing slows a commit.
- *Bad:* the broken commit already exists, so small commits can carry
  breakage between them, and the developer reviews unchecked work.

### Option 4: Do nothing

- *Good:* nothing to build or maintain.
- *Bad:* releasability and the record contract stay habits, and the
  header hook keeps working without a decision behind it.

## More information

Agreed 2026-10-08 as the local half of a two-tier gate; named for its
mechanism on 2026-10-29, with the hosted check a record of its own.

Open point: the checks read the working tree, so an unstaged fix can hide
a staged error, and a check not yet staged runs on a commit that lacks it.
Reading the index instead waits for the first such error to reach a commit.
