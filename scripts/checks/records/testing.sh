# Helpers sourced by each records/*.test.sh: each case writes one record
# into a throwaway directory, edits it, and expects records.sh to pass or to
# report a message. A test file ends by calling finish.

checks=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)
fixtures="${TMPDIR:-/tmp}/records-test.$$"
trap 'rm -rf "$fixtures"' EXIT
failures=0

# Prints a record that satisfies every check, numbered 1.
valid_record() {
  cat "$checks/records/valid.md"
}

# The number of the first line appended after the valid record.
appended=$(($(valid_record | wc -l) + 1))

# Prints the value of the front matter field in the record, its first
# occurrence only.
value() {
  sed -n "/^$1: /{s///p;q;}" "$2"
}

# Prints the index the records written to the fixtures call for.
index_of() {
  local record name
  printf '## Index\n\n| Number | Title | Area | Status |\n|---|---|---|---|\n'
  for record in "$fixtures"/[1-9]*.md; do
    name=${record##*/}
    printf '| [%s](%s) | %s | %s | %s |\n' "${name%%-*}" "$name" \
      "$(value title "$record")" "$(value area "$record")" \
      "$(value status "$record")"
  done
}

# Writes the valid record edited by the sed script, and a valid record 2
# after it, edited by the sed script in $second when set, and the index
# they call for, edited by the sed script in $readme when set; then runs
# records.sh on them, prints the findings, and returns the exit status.
run_edited() {
  rm -rf "$fixtures" && mkdir -p "$fixtures"
  valid_record | sed -e "$1" > "$fixtures/1-do-one-thing.md"
  valid_record | sed -e 's/ADR-1:/ADR-2:/' -e "${second:-}" \
    > "$fixtures/2-do-one-thing.md"
  index_of | sed -e "${readme:-}" > "$fixtures/README.md"
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
