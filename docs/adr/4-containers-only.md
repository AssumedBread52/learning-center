---
title: Containers only
status: Implementing
date: 2026-10-03
area: toolchain
trigger: none
supersedes: none
superseded_by: none
---

# ADR-4: Containers only

## Context and problem statement

Software installed for a project outlives its use: a runtime, a package
manager, or a database stays on the machine long after the project stopped
needing it, at a version nothing tracks. The application needs a runtime, a
package manager, a database, and test runners now, and later a search
engine, a telemetry stack, and a gateway, and more than one copy of the
stack may run on one machine. Where does the toolchain live, and what may
touch the host?

## Decision drivers

- *Nothing left behind:* when a tool is dropped, the host is as it was.
- *One version in one place*, so a bump is a one-line change.
- *Files the developer keeps are theirs*, whoever wrote them.
- *The same commands everywhere*, on every machine and in the checks.

## Considered options

1. *Published images, host uid passthrough, utility containers.*
2. *Project Dockerfiles with the toolchain baked in.*
3. *The toolchain installed on the host under a version manager*, with only
   the services in containers.
4. *Do nothing:* no convention; each need is met as it comes, which means
   the first `npm install` lands on the host.

## Decision outcome

Chosen option: 1, *published images, host uid passthrough, utility
containers*, because it is the only option that leaves the host untouched
while keeping one version of each tool in one place.

- *Host prerequisites, and nothing else:* Docker with Compose, git, and a
  shell. The rule is about installing: tools the operating system already
  ships (`python3`, `sed`, `awk`) are fair game, and hook scripts stay
  within bash, git, and coreutils.
- *No Dockerfiles, images as published,* named by the software and an exact
  tag (`node:24.21.0`, `postgres:18.6`; two numbers where the software uses
  two), never an `alpine` variant. A vendor-namespaced image, such as
  `grafana/grafana:11.2.0` or the browser-testing image, is accepted when
  no exactly tagged official image exists.
- *The image tag is the version manager.* Each version lives in one `.env`
  variable (`NODE_IMAGE=node:24.21.0`) referenced by every service and
  utility container that uses it, and mirrored in `package.json`'s
  `engines` field once there is one; the Compose variable drives.
- *Bind-mounted files are owned by the host user.* Containers that write
  to the bind mount run as `user: "${USER_ID}:${GROUP_ID}"`;
  `scripts/up.sh` writes the git-ignored `.env` from `id -u` and `id -g`,
  and is the only template for it, so no `.env.example` is committed.
  Service state lives in named volumes under the image's own user, and the
  Compose file says so where the service is declared.
- *Utility containers for tooling.* Package managers and other tools run as
  one-off containers sharing the image, user, and bind mount of what they
  serve, under a `tools` profile that `up` ignores. A uid the image does
  not know gets its home in a named volume, and non-root processes take
  high ports. The Compose project name comes from the directory, so two
  copies of the stack run side by side.
- *Consequence for the developer:* every build, test, lint, package, or
  script command goes through `docker compose run --rm <utility> ...` or
  `docker compose exec <service> ...`, never `npm`, `node`, `pip`, or
  similar on the host.

### Consequences

- *Good:* the host is left as found; dropping a tool is deleting a Compose
  service and pruning an image.
- *Good:* exact tags make every environment reproducible, and a tag bump
  is a one-line pull request.
- *Bad:* every tool invocation starts a container, one to two seconds per
  `docker compose run`, so tight loops run in a long-lived container, such
  as a test runner in watch mode.
- *Bad:* some needs touch the host without installing anything: a search
  engine's `vm.max_map_count` is a kernel setting, which that engine's
  record must address.

### Reversal

Cheap in code, costly in habit. The artifacts are the Compose file and the
bootstrap script; reversing means installing a toolchain on the host and
rewriting every invocation in the checks and the deployment. The later
records that pin a version by image tag, the runtime's, the database's, the
browser-testing image's, and the editor's, would reopen.

### Confirmation

A check written with the build gate's record: no `Dockerfile`,
`*.Dockerfile`, or `Containerfile` exists, and every image that
`docker compose config --images` resolves names an exact tag (never bare,
`latest`, a floating major, or `-alpine`), with the accepted exceptions
listed inline. Review until then.

## Pros and cons of the options

### Option 1: Published images, host uid passthrough, utility containers

- *Good:* nothing on the host; one version per tool, in one place.
- *Bad:* a start-up cost per invocation, and a host uid absent from the
  image's `/etc/passwd` needs its home directory provided.

### Option 2: Project Dockerfiles with the toolchain baked in

- *Good:* any tool can be added, and creating the uid in the image removes
  the home-directory workaround.
- *Bad:* a second place where software is installed and drifts; building
  it is a toolchain step; published updates no longer arrive as a tag bump.

### Option 3: The toolchain installed on the host under a version manager

- *Good:* no start-up cost, and the editor and debugger need no bridge.
- *Bad:* exactly the failure this avoids, installed software that outlives
  its use; a version manager duplicates what the image tag already does;
  host and container can differ.

### Option 4: Do nothing

- *Good:* nothing to set up before the first commit.
- *Bad:* the first convenience install happens, the host drifts, and every
  later record that assumes Compose has no basis.

## More information

Sources: the brainstorming notes (*Toolchain in containers only*, *Tech
stack and tooling*, and the agreement *No software installed on the host*).
Agreed 2026-10-03; no `.env.example`, since the script is the template,
2026-10-16.
