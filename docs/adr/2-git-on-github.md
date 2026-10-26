---
title: Git on GitHub
status: Implementing
date: 2026-10-05
area: repository
trigger: none
supersedes: none
superseded_by: none
---

# ADR-2: Git on GitHub

## Context and problem statement

Every later practice assumes a version-control system and a host: the commit
history shows where each decision was made, and changes are to reach the
production branch through reviewed pull requests. The repository is public
because it doubles as a demonstration of skill, so the history only counts if
the people it is meant for can find and read it. The choice was made when the
repository was created and never written down. Which version-control system
holds the history, and where is it hosted?

## Decision drivers

- *The history is the record.* Commits, merges, and their order must survive any
  later change of host or tool.
- *The exhibit reaches its readers.* A public repository is worth what its
  readers can browse, review, and clone without an account elsewhere.
- *Review and checks at the host.* Pull requests, branch protection, and hosted
  checks on every pull request, with no server to run.

## Considered options

1. *Git on GitHub.*
2. *Git on GitLab.*
3. *Git on Codeberg*, a non-profit host running Forgejo.
4. *Git on a self-hosted forge*, such as Forgejo on the developer's machine.
5. *Another version-control system* (added for completeness): Mercurial or
   Fossil.
6. *Do nothing*: the repository stays where it was created, on GitHub, with no
   record of why, so moving it or adding host features has nothing to weigh.

## Decision outcome

Chosen option: 1, *git on GitHub*, because git's history moves whole between
the hosts that speak it, and GitHub is where a public repository's readers
already are and supplies pull requests, branch protection, and hosted checks
without a server to run.

- *Git holds everything the history needs.* Decisions, their commits, and the
  merges that brought them in live in the repository itself, so a mirror push
  to another host carries the record whole. Host features may group, protect,
  and check that history; they never replace it.
- *The host is GitHub.* The application repository is
  `AssumedBread52/learning-center`, public from its first commit. Pull
  requests, branch protection, and hosted checks are GitHub's, each configured
  by the record that needs it.
- *What the repository carries for it.* A root `.gitignore`, empty until
  something needs ignoring; each entry lands in the commit that brings what it
  ignores, so every line has a cause in the log.

### Consequences

- *Good:* git is what every tool here already speaks, from the editor to the
  container images, so nothing needs an adapter.
- *Good:* the history moves between hosts intact, so the host is a door, not a
  wall.
- *Bad:* pull-request descriptions and their discussion live on GitHub, not in
  git; only the merge commit's header reaches the log.
- *Bad:* hosted checks run on GitHub's terms and quotas, which can change.

### Reversal

Moderate for the host: a mirror push moves branches and history in minutes,
while pull requests, branch protection, and hosted-check workflows are rebuilt
by hand. Heavy for git itself: every hook and the build gate would reopen.
Depends on it: ADR-1, whose history marks are git commits, and every later
record about branches, hooks, or checks.

## Pros and cons of the options

### Option 1: Git on GitHub

- *Good:* argued above; the largest public audience and no server to run.
- *Bad:* a proprietary host; its features and terms are not the project's.

### Option 2: Git on GitLab

- *Good:* merge requests and integrated checks of the same kind, and an
  open-core edition that could be self-hosted later.
- *Bad:* a smaller public audience for the exhibit, and no capability the
  project needs that GitHub lacks.

### Option 3: Git on Codeberg

- *Good:* a non-profit, open-source host, aligned with an open-source project.
- *Bad:* the smallest audience of the hosts, and shared check runners with
  tighter capacity than the gate will want.

### Option 4: Git on a self-hosted forge

- *Good:* full control of data, features, and checks.
- *Bad:* the application runs only locally, so a forge on the same machine is
  not public, which defeats the exhibit; and it is a server to run.

### Option 5: Another version-control system

- *Good:* Fossil bundles tickets and a wiki with the history; Mercurial has a
  gentler command set.
- *Bad:* hosting for either is scarce, and the editor, the containers, and every
  reader assume git, so each would need adapters or explanation.

### Option 6: Do nothing

- *Good:* nothing to write; the repository already works.
- *Bad:* every tool choice gets a record, and an unrecorded one leaves
  the next move between hosts, or the next host feature, with no reasons to
  weigh against.

## More information

Sources: the brainstorming notes (initialization; hosting agreed 2026-10-05).
The repository was created on GitHub on 2026-10-20; this record was raised on
2026-10-26, when review found that later records assumed git and GitHub with no
record of their own.
