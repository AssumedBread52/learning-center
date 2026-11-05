#!/usr/bin/env bash
# Tests of scripts/check.sh and the pre-commit hook that calls it: each case
# writes a throwaway git repository whose scripts/checks/ holds stand-in
# checks, runs check.sh or the hook on it, and expects a status and output.
set -euo pipefail

# Unsets the variables a git hook exports, which name the index and
# repository of the commit under way, so that git in each fixture acts on
# the fixture and never on the commit.
forget_enclosing_repository() {
  unset $(git rev-parse --local-env-vars)
}

forget_enclosing_repository
scripts=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)
fixtures="${TMPDIR:-/tmp}/check-test.$$"
trap 'rm -rf "$fixtures"' EXIT
failures=0

# Writes a repository with check.sh and the hook, and one stand-in check
# per argument NAME:STATUS, which prints its name and exits with STATUS.
write_fixture() {
  local entry
  rm -rf "$fixtures" && mkdir -p "$fixtures/scripts/checks" \
    "$fixtures/.githooks" && git -C "$fixtures" init -q
  cp "$scripts/check.sh" "$fixtures/scripts/check.sh"
  cp "$scripts/../.githooks/pre-commit" "$fixtures/.githooks/pre-commit"
  for entry in "$@"; do
    printf 'echo "ran %s"; exit %s\n' "${entry%:*}" "${entry#*:}" \
      > "$fixtures/scripts/checks/${entry%:*}.sh"
  done
}

fail() {
  echo "FAIL  $1"
  failures=$((failures + 1))
}

# Runs the command $run (check.sh by default) in a fixture of the stand-ins
# and expects the status and, in order, each line of the expected output.
expect() {
  local name=$1 status=$2 expected=$3 output actual=0
  shift 3
  write_fixture "$@"
  output=$(cd "$fixtures" && ${run:-bash scripts/check.sh} 2>&1) || actual=$?
  if [ "$actual" != "$status" ]; then
    fail "${name}: expected status ${status}, got ${actual}: ${output}"
  elif [ "$output" != "$expected" ]; then
    fail "${name}: expected \"${expected}\", got \"${output}\""
  fi
}

refused='check: failing checks: scripts/checks/b.sh scripts/checks/d.sh'

expect 'every check passes' 0 $'ran a\nran b' a:0 b:0
expect 'checks run in name order' 0 $'ran a\nran b\nran c' c:0 a:0 b:0
expect 'every check runs after a failure, the failing named' 1 \
  $'ran a\nran b\nran c\nran d\n'"$refused" a:0 b:1 c:0 d:1
run='bash .githooks/pre-commit' expect 'the hook passes' 0 'ran a' a:0
run='bash .githooks/pre-commit' expect 'the hook refuses' 1 \
  $'ran a\nran b\nran c\nran d\n'"$refused"$'\npre-commit: refused' \
  a:0 b:1 c:0 d:1

if [ "$failures" -gt 0 ]; then exit 1; fi
