#!/usr/bin/env bash
# Tests of heading.awk, through records.sh.
set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/testing.sh"

expected='is not "# ADR-1: Do one thing"'

expect_clean 'a retitled record' "$(title 'Do two things')"
expect_finding 'a heading with another number' 's/^# ADR-1:/# ADR-3:/' \
  "11: heading \"# ADR-3: Do one thing\" ${expected}"
expect_finding 'a heading with another title' \
  's/^# ADR-1: .*/# ADR-1: Do two things/' \
  "11: heading \"# ADR-1: Do two things\" ${expected}"
expect_finding 'a title with another heading' "$(field title 'Do two things')" \
  '11: heading "# ADR-1: Do one thing" is not "# ADR-1: Do two things"'
expect_finding 'a second-level heading' 's/^# ADR/## ADR/' \
  "11: heading \"## ADR-1: Do one thing\" ${expected}"
expect_finding 'no heading' '/^# ADR-1:/d' \
  "12: heading \"## Context and problem statement\" ${expected}"
expect_finding 'nothing after the front matter' '10,$d' \
  '9: heading missing; expected "# ADR-1: Do one thing"'
expect_absent 'no front matter judged for a heading' '1d' 'heading'

finish
