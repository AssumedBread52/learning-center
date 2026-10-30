#!/usr/bin/env bash
# Tests of length.awk, through records.sh.
set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/testing.sh"

# Prints one word per line from line 12, after the valid record, to the
# given line number.
filler() {
  local line
  for ((line = 12; line <= $1; line++)); do echo x; done
}

expect_clean 'exactly 150 lines' "$(append $(filler 150))"
expect_finding 'more than 150 lines' "$(append $(filler 151))" \
  '151: 151 lines; the ceiling is 150'

finish
