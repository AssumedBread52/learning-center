#!/usr/bin/env bash
# Tests of images.sh: each case writes a throwaway git repository holding a
# compose.yaml shaped like the real one, a profiled service whose user needs
# the .env, and expects images.sh to pass or to report a message.
set -euo pipefail

# Unsets the variables a git hook exports, which name the index and
# repository of the commit under way, so that git in each fixture acts on
# the fixture and never stages into the commit.
forget_enclosing_repository() {
  unset $(git rev-parse --local-env-vars)
}

forget_enclosing_repository
checks=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)
fixtures="${TMPDIR:-/tmp}/images-test.$$"
trap 'rm -rf "$fixtures"' EXIT
failures=0

# Writes a repository whose one service uses the image, or that has no
# service when the image is empty; stages each further argument as an
# empty file, and writes the file in $untracked without staging it; then
# runs images.sh on it, prints the findings, and returns the exit status.
run_with() {
  local image=$1 file
  shift
  rm -rf "$fixtures" && mkdir -p "$fixtures" && git -C "$fixtures" init -q
  if [ -z "$image" ]; then
    echo 'services: {}' > "$fixtures/compose.yaml"
  else
    cat > "$fixtures/compose.yaml" <<COMPOSE
services:
  node:
    profiles: ["tools"]
    image: ${image}
    user: "\${USER_ID:?run scripts/up.sh}:\${GROUP_ID:?run scripts/up.sh}"
COMPOSE
  fi
  for file in "$@"; do
    mkdir -p "$(dirname "$fixtures/$file")" && : > "$fixtures/$file"
    git -C "$fixtures" add "$file"
  done
  if [ -n "${untracked:-}" ]; then : > "$fixtures/$untracked"; fi
  bash "$checks/images.sh" "$fixtures"
}

expect_clean() {
  local name=$1 output
  shift
  if output=$(run_with "$@" 2>&1); then return; fi
  echo "FAIL  ${name}: expected no findings, got: ${output}"
  failures=$((failures + 1))
}

expect_finding() {
  local name=$1 message=$2 output
  shift 2
  if output=$(run_with "$@" 2>&1); then
    echo "FAIL  ${name}: expected \"${message}\", got no findings"
    failures=$((failures + 1))
  elif ! grep -qF -- "$message" <<< "$output"; then
    echo "FAIL  ${name}: expected \"${message}\", got: ${output}"
    failures=$((failures + 1))
  fi
}

tag='is not named by a MAJOR.MINOR.PATCH tag'
recipe='an image recipe; images are published ones (ADR-4)'

expect_clean 'an exact tag' node:24.21.0
expect_clean 'an exact tag under a registry path' ghcr.io/org/node:24.21.0
expect_finding 'a bare name' "image \"node\" ${tag}" node
expect_finding 'latest' "image \"node:latest\" ${tag}" node:latest
expect_finding 'a floating major' "image \"node:24\" ${tag}" node:24
expect_finding 'a floating minor' "image \"node:24.21\" ${tag}" node:24.21
expect_finding 'a variant' "image \"node:24.21.0-alpine\" ${tag}" \
  node:24.21.0-alpine
expect_finding 'a digest' 'image "node@sha256:' \
  "node@sha256:$(printf '0%.0s' {1..64})"
expect_finding 'no images' 'compose.yaml: no images resolved' ''

expect_finding 'a Dockerfile' "Dockerfile: ${recipe}" node:24.21.0 Dockerfile
expect_finding 'a nested named Dockerfile' "tools/app.Dockerfile: ${recipe}" \
  node:24.21.0 tools/app.Dockerfile
expect_finding 'a Containerfile' "Containerfile: ${recipe}" node:24.21.0 \
  Containerfile
expect_clean 'a file merely mentioning Dockerfile' node:24.21.0 Dockerfile.md
expect_clean 'a name merely ending in Dockerfile' node:24.21.0 myDockerfile
expect_finding 'a recipe in a path with a space' "my tools/Dockerfile: " \
  node:24.21.0 'my tools/Dockerfile'
untracked=Dockerfile expect_clean 'an untracked Dockerfile' node:24.21.0

if [ "$failures" -gt 0 ]; then exit 1; fi
