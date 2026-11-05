#!/usr/bin/env bash
# Tests of scripts/headers.sh: each case writes a throwaway git repository
# with headers.sh and the commit-msg hook, makes a base commit and the
# commits of a branch after it, and expects headers.sh over the branch to
# pass or to name the commits whose message the hook rejects.
set -euo pipefail

# Unsets the variables a git hook exports, which name the index and
# repository of the commit under way, so that git in each fixture acts on
# the fixture and never on the commit.
forget_enclosing_repository() {
  unset $(git rev-parse --local-env-vars)
}

forget_enclosing_repository
scripts=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)
fixtures="${TMPDIR:-/tmp}/headers-test.$$"
trap 'rm -rf "$fixtures"' EXIT
failures=0

# Commits an empty change in the fixture with the message, bypassing the
# fixture's hooks, since the messages under test are meant to break them.
commit() {
  git -C "$fixtures" -c user.name=t -c user.email=t@t commit -q \
    --allow-empty --no-verify -m "$1"
}

# Writes the fixture, commits the base with the message $base or a valid
# one, then one commit per argument; runs headers.sh from the base to the
# last commit, prints its output, and returns its status.
run_with() {
  local message
  rm -rf "$fixtures" && mkdir -p "$fixtures/scripts" "$fixtures/.githooks"
  git -C "$fixtures" init -q
  cp "$scripts/headers.sh" "$fixtures/scripts/headers.sh"
  cp "$scripts/../.githooks/commit-msg" "$fixtures/.githooks/commit-msg"
  commit "${base:-ADR-1: start}"
  local first
  first=$(git -C "$fixtures" rev-parse HEAD)
  for message in "$@"; do commit "$message"; done
  (cd "$fixtures" && bash scripts/headers.sh "$first" HEAD)
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

expect_clean 'valid headers' 'ADR-1: do one thing' 'ADR-2: do another'
expect_clean 'a merge git wrote' 'ADR-1: do one thing' \
  'Merge pull request #1 from someone/ADR-1'
base='a base that breaks the rule' expect_clean 'commits before the range' \
  'ADR-1: do one thing'
expect_finding 'a header ending in a period' \
  "commit-msg: header is not 'ADR-N: description'" \
  'ADR-1: do one thing' 'ADR-2: do another.'
expect_finding 'the commit named' 'got: ADR-2: do another.' \
  'ADR-2: do another.'
expect_finding 'a body' 'bodies and footers are not checked yet' \
  $'ADR-1: do one thing\n\nA body.'
expect_finding 'every failing commit, not only the first' 'got: Second bad' \
  'First bad' 'ADR-1: fine' 'Second bad'

if [ "$failures" -gt 0 ]; then exit 1; fi
