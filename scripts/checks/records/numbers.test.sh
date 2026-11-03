#!/usr/bin/env bash
# Tests of numbers.awk, through records.sh.
set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/testing.sh"

third=3-do-one-thing.md expect_absent 'three numbers' '' 'is already used by'
third=1-do-two-things.md expect_finding 'a number used twice' '' \
  '1-do-two-things.md:1: number 1 is already used by 1-do-one-thing.md'

finish
