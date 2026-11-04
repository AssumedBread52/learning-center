#!/usr/bin/env bash
# Tests of entry-dates.sh: each case writes a throwaway git repository,
# stages records in its docs/adr, and expects entry-dates.sh to pass or to
# report a message.
set -euo pipefail

# Unsets the variables a git hook exports, which name the index and
# repository of the commit under way, so that git in each fixture acts on
# the fixture and never stages into the commit.
forget_enclosing_repository() {
  unset $(git rev-parse --local-env-vars)
}

forget_enclosing_repository
checks=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)
fixtures="${TMPDIR:-/tmp}/entry-dates-test.$$"
trap 'rm -rf "$fixtures"' EXIT
today=$(date +%Y-%m-%d)
failures=0

# Writes the record docs/adr/$1 in the fixture with the date $2.
write_record() {
  mkdir -p "$fixtures/docs/adr"
  printf -- '---\ntitle: Do one thing\nstatus: Implementing\ndate: %s\n---\n' \
    "$2" > "$fixtures/docs/adr/$1"
}

# Writes a fresh repository, then runs each argument as a shell command in
# it, with write_record and git at hand; then runs entry-dates.sh on it,
# prints the findings, and returns the exit status.
run_with() {
  local step
  rm -rf "$fixtures" && mkdir -p "$fixtures" && git -C "$fixtures" init -q
  for step in "$@"; do (cd "$fixtures" && eval "$step"); done
  bash "$checks/entry-dates.sh" "$fixtures"
}

commit_all() {
  git add -A && git -c user.name=t -c user.email=t@t commit -q -m 'ADR-1: x'
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

stale="date 2000-01-01 is not the entry day ${today}"

expect_clean 'nothing staged' ':'
expect_clean 'a new record dated today' \
  "write_record 1-a.md $today && git add -A"
expect_finding 'a new record dated another day' \
  "docs/adr/1-a.md: ${stale}" "write_record 1-a.md 2000-01-01 && git add -A"
expect_finding 'the second of two new records' "docs/adr/2-b.md: ${stale}" \
  "write_record 1-a.md $today && write_record 2-b.md 2000-01-01" 'git add -A'
expect_finding 'a stale date staged, today only in the working tree' \
  "docs/adr/1-a.md: ${stale}" "write_record 1-a.md 2000-01-01 && git add -A" \
  "write_record 1-a.md $today"
expect_clean 'a record already entered, edited' \
  "write_record 1-a.md 2000-01-01 && commit_all" \
  "echo edit >> docs/adr/1-a.md && git add -A"
expect_clean 'the template' "write_record 0-template.md 2000-01-01 && git add -A"
expect_clean 'the index' 'mkdir -p docs/adr && echo x > docs/adr/README.md' \
  'git add -A'
expect_clean 'a dated file outside docs/adr' \
  "write_record 1-a.md 2000-01-01 && mv docs/adr/1-a.md . && git add -A"

if [ "$failures" -gt 0 ]; then exit 1; fi
