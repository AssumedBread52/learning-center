#!/usr/bin/env bash
# Tests of records.sh: each case writes one record into a throwaway
# directory, edits it, and expects records.sh to pass or to report a message.
set -euo pipefail

checks=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)
fixtures="${TMPDIR:-/tmp}/records-test.$$"
trap 'rm -rf "$fixtures"' EXIT
failures=0

# Prints a record that satisfies every check, numbered 1.
valid_record() {
  cat <<'RECORD'
---
title: Do one thing
status: Implementing
date: 2026-10-29
area: process
trigger: none
supersedes: none
superseded_by: none
---

# ADR-1: Do one thing
RECORD
}

# Writes the valid record edited by the sed script, and a valid record 2
# after it, then runs records.sh on both; prints the findings and returns
# the exit status.
run_edited() {
  rm -rf "$fixtures" && mkdir -p "$fixtures"
  valid_record | sed -e "$1" > "$fixtures/1-do-one-thing.md"
  valid_record | sed -e 's/ADR-1:/ADR-2:/' > "$fixtures/2-do-one-thing.md"
  bash "$checks/records.sh" "$fixtures"
}

# Prints a sed script setting the front matter field to the value.
field() {
  printf 's|^%s: .*|%s: %s|' "$1" "$1" "$2"
}

# Prints a line of the given width, prefixed.
wide() {
  local line=$1
  while [ "${#line}" -lt "$2" ]; do line="${line}w"; done
  printf '%s' "$line"
}

# Prints a sed script appending each argument as a line at the end.
append() {
  local line script='$a\'
  for line in "$@"; do script="${script}"$'\n'"${line}\\"; done
  printf '%s' "${script%\\}"
}

# Prints one word per line from line 12, after the valid record, to the
# given line number.
filler() {
  local line
  for ((line = 12; line <= $1; line++)); do echo x; done
}

expect_clean() {
  local name=$1 edit=$2 output
  if output=$(run_edited "$edit" 2>&1); then return; fi
  echo "FAIL  ${name}: expected no findings, got: ${output}"
  failures=$((failures + 1))
}

expect_absent() {
  local name=$1 edit=$2 text=$3 output
  output=$(run_edited "$edit" 2>&1) || true
  if grep -qF -- "$text" <<< "$output"; then
    echo "FAIL  ${name}: expected no \"${text}\", got: ${output}"
    failures=$((failures + 1))
  fi
}

expect_finding() {
  local name=$1 edit=$2 message=$3 output
  if output=$(run_edited "$edit" 2>&1); then
    echo "FAIL  ${name}: expected \"${message}\", got no findings"
    failures=$((failures + 1))
  elif ! grep -qF -- "$message" <<< "$output"; then
    echo "FAIL  ${name}: expected \"${message}\", got: ${output}"
    failures=$((failures + 1))
  fi
}

expect_clean 'a valid record' ''
expect_clean 'a superseded record' \
  "$(field status 'Superseded by ADR-2'); $(field superseded_by ADR-2)"

expect_finding 'no front matter' '1d' '1: front matter missing'
expect_finding 'an unclosed front matter' '9d' \
  '1-do-one-thing.md:1: front matter is never closed'

expected='expected "title status date area trigger supersedes superseded_by"'
expect_finding 'fields out of order' '/^area:/{h;d;}; /^trigger:/G' \
  'are "title status date trigger area supersedes superseded_by"'
expect_finding 'a missing field' '/^trigger:/d' "$expected"
expect_finding 'an unknown field' '/^area:/a\
foo: bar' "$expected"
expect_absent 'an unknown field judged as a value' '/^area:/a\
foo: bar' 'foo "bar"'

expect_finding 'an empty title' "$(field title '')" '2: title "" is not'
expect_finding 'a draft status' "$(field status Draft)" 'status "Draft"'
expect_finding 'a date in another form' "$(field date 29/10/2026)" \
  'date "29/10/2026"'
expect_finding 'an area not in kebab case' "$(field area Process)" \
  'area "Process"'
expect_finding 'a trigger outside the set' "$(field trigger maybe)" \
  'trigger "maybe"'
expect_finding 'a padded supersedes' "$(field supersedes ADR-02)" \
  'supersedes "ADR-02"'
expect_finding 'a bare superseded_by' "$(field superseded_by 2)" \
  'superseded_by "2"'

expect_clean 'prose exactly 80 columns' "$(append "$(wide '' 80)")"
expect_finding 'prose wider than 80 columns' "$(append "$(wide '' 81)")" \
  '12: 81 columns; prose wraps at 80'
expect_clean 'a wide heading' "$(append "$(wide '## ' 90)")"
expect_clean 'a wide table row' "$(append "$(wide '| ' 90)")"
expect_clean 'a wide line carrying a URL' \
  "$(append "$(wide 'See https://example.test/' 90)")"
expect_clean 'a wide title' "$(field title "$(wide '' 90)")"
expect_clean 'exactly 150 lines' "$(append $(filler 150))"
expect_finding 'more than 150 lines' "$(append $(filler 151))" \
  '151: 151 lines; the ceiling is 150'

if [ "$failures" -gt 0 ]; then exit 1; fi
