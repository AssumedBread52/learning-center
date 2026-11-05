---
title: GitHub Actions
status: Implementing
date: 2026-11-05
area: process
trigger: deliberate
supersedes: none
superseded_by: none
---

# ADR-6: GitHub Actions

## Context and problem statement

The versioned git hooks (ADR-5) stop most broken commits where they are
made, but they run on the client: `--no-verify` skips them, a clone that
never ran the up script lacks them, and a commit made anywhere else (an
edit on GitHub, a bot's pull request, a contributor's fork) never meets
them. Branch protection lets `main` change only by pull request (ADR-3),
yet nothing checks what a pull request carries. The gap is raised
deliberately: the cheap check came first, and the gap is closed before it
is exploited rather than after. What checks a pull request before it can
merge?

## Decision drivers

- *The same checks as the hooks*, so a result on GitHub means what it
  means locally.
- *Nothing installed on the runner* beyond what it ships, the rule the
  hooks keep on the host (ADR-4, ADR-5).
- *Least privilege* for anything that runs code from a pull request.

## Considered options

1. *GitHub Actions*, required by branch protection.
2. *Another hosted service* (CircleCI, Buildkite, GitLab CI on a mirror).
3. *A self-hosted runner* on the developer's machine.
4. *Do nothing:* the hooks stay the only check, and a pull request that
   skipped them merges unchecked.

## Decision outcome

Chosen option: 1, *GitHub Actions*, because it lives in the repository the
pull requests already live in, costs nothing for a public repository, and
needs no account or machine beyond GitHub.

- *One script, two callers.* The loop that runs every check in
  `scripts/checks/` moves from the `pre-commit` hook into a versioned
  script that the hook and the workflow both call, so local and hosted
  results cannot diverge. A check is still added once, as a file in
  `scripts/checks/`, and runs on the host or through `docker compose run`
  as ADR-5 lets it choose.
- *Every pull request, every commit.* The workflow runs the script on the
  pull request's head and checks every commit header on the branch with
  the `commit-msg` hook, which otherwise runs only on the client.
- *Required.* Branch protection on `main` requires the check, so a pull
  request whose check fails cannot merge.
- *Pinned and least-privileged.* Third-party actions are pinned by full
  commit SHA, never by a tag that can move; the workflow token is
  read-only (`contents: read`); pull requests from forks run without
  secrets, of which there are none.
- *Slower checks belong here.* A check too slow for a commit, or needing
  services, browsers, or the production build, runs only in the hosted
  check; its record says so.

### Consequences

- *Good:* nothing merges into `main` unchecked, however it was committed.
- *Good:* the hooks stay as the early, cheap stop; the hosted check is
  the backstop, so neither replaces the other.
- *Bad:* a second place where checks run, so the script, not either
  caller, must hold every step.
- *Bad:* a bot's commit message will fail the header check; how bots are
  treated is settled when the first one is adopted.

### Reversal

Cheap: one workflow file and one branch-protection setting; another
hosted service means rewriting the workflow alone, since the script holds
every step. Builds on ADR-3, whose branch protection it extends, and on
ADR-5, whose hooks run the checks it shares.

### Confirmation

The check confirms itself: branch protection lists it as required, and a
pull request whose check fails shows it failing and cannot merge.

## Pros and cons of the options

### Option 1: GitHub Actions

Argued in the outcome. *Bad:* vendor-specific workflow syntax.

### Option 2: Another hosted service

- *Good:* some offer faster runners or richer caching.
- *Bad:* a second account, a second permission model, and integration
  work for no need the project has.

### Option 3: A self-hosted runner

- *Good:* no minutes limit, and the images are already cached.
- *Bad:* runs code from pull requests on the developer's machine, which
  a public repository makes unsafe; checks stop when the machine sleeps.

### Option 4: Do nothing

- *Good:* nothing to build.
- *Bad:* the gap the context names stays open, and branch protection
  guards a door with no lock.

## More information

The hosted half of the gate whose local half is ADR-5. Open: the bot
policy, and the time budget of the hosted check once it carries slow
steps.
