#!/usr/bin/env bash
# Tests of do-nothing.awk, through records.sh.
set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/testing.sh"

expected='34: no "### Option K: Do nothing" under the pros and cons'
renamed='s/^### Option 2: Do nothing$/### Option 2: Wait/'

expect_clean 'Do nothing as the first option' \
  's/^### Option 1: One thing$/### Option 1: Do nothing/
s/^### Option 2: Do nothing$/### Option 2: One thing/'
expect_finding 'no Do nothing option' "$renamed" "$expected"
expect_finding 'Do nothing after the pros and cons' \
  "${renamed}"$'\n'"$(append '' '## More information' '' \
    '### Option 2: Do nothing')" \
  "$expected"
expect_absent 'no pros and cons judged for Do nothing' \
  '/^## Pros and cons of the options$/d' 'Do nothing'

finish
