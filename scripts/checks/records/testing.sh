# Helpers sourced by each records/*.test.sh: each case writes one record
# into a throwaway directory, edits it, and expects records.sh to pass or to
# report a message. A test file ends by calling finish.

checks=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)
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

## Context and problem statement

Should the project do one thing?

## Considered options

1. One thing.
2. Do nothing: keep things as they are.

## Decision outcome

Chosen option: 1, *one thing*, because it is enough.

### Consequences

- Good: one thing is done.

### Reversal

Cheap; no records depend on it.

## Pros and cons of the options

### Option 1: One thing

- Good: it is enough.

### Option 2: Do nothing

- Bad: nothing is done.
RECORD
}

# The number of the first line appended after the valid record.
appended=$(($(valid_record | wc -l) + 1))

# Writes the valid record edited by the sed script, and a valid record 2
# after it, edited by the sed script in $second when set, then runs
# records.sh on both; prints the findings and returns the exit status.
run_edited() {
  rm -rf "$fixtures" && mkdir -p "$fixtures"
  valid_record | sed -e "$1" > "$fixtures/1-do-one-thing.md"
  valid_record | sed -e 's/ADR-1:/ADR-2:/' -e "${second:-}" \
    > "$fixtures/2-do-one-thing.md"
  bash "$checks/records.sh" "$fixtures"
}

# Prints a sed script setting the front matter field to the value.
field() {
  printf 's|^%s: .*|%s: %s|' "$1" "$1" "$2"
}

# Prints a sed script setting the title in the front matter and the heading.
title() {
  printf '%s; s|^# ADR-\\([0-9]*\\): .*|# ADR-\\1: %s|' \
    "$(field title "$1")" "$1"
}

# Prints a sed script appending each argument as a line at the end.
append() {
  local line script='$a\'
  for line in "$@"; do script="${script}"$'\n'"${line}\\"; done
  printf '%s' "${script%\\}"
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

# Exits 1 when any case failed.
finish() {
  if [ "$failures" -gt 0 ]; then exit 1; fi
}
