#!/usr/bin/env bash
# Tests of width.awk, through records.sh.
set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/testing.sh"

# Prints a line of the given width, prefixed.
wide() {
  local line=$1
  while [ "${#line}" -lt "$2" ]; do line="${line}w"; done
  printf '%s' "$line"
}

expect_clean 'prose exactly 80 columns' "$(append "$(wide '' 80)")"
expect_finding 'prose wider than 80 columns' "$(append "$(wide '' 81)")" \
  '12: 81 columns; prose wraps at 80'
expect_clean 'a wide heading' "$(append "$(wide '## ' 90)")"
expect_clean 'a wide table row' "$(append "$(wide '| ' 90)")"
expect_clean 'a wide line carrying a URL' \
  "$(append "$(wide 'See https://example.test/' 90)")"
expect_clean 'a wide title' "$(field title "$(wide '' 90)")"

finish
