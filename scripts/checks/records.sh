#!/usr/bin/env bash
# Checks every record in a directory, docs/adr by default, against the
# record contract in that directory's README.md (ADR-1), running each AWK
# program in records/ over them. Prints one file:line: message per finding
# and exits 1 when any program found one.
set -euo pipefail

PROGRAMS=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)/records

main() {
  local directory=${1:-docs/adr} program status=0
  for program in "$PROGRAMS"/*.awk; do
    awk -f "$program" "$directory"/[1-9]*.md || status=1
  done
  exit "$status"
}

main "$@"
