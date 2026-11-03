#!/usr/bin/env bash
# Runs the tests of every record program, each records/*.test.sh, all of
# them even after one fails, and exits 1 when any failed.
set -euo pipefail

TESTS=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)/records

main() {
  local test status=0
  for test in "$TESTS"/*.test.sh; do
    bash "$test" || status=1
  done
  exit "$status"
}

main "$@"
