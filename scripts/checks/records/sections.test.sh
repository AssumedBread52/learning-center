#!/usr/bin/env bash
# Tests of sections.awk, through records.sh.
set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/testing.sh"

expect_clean 'the optional sections in their places' \
  '/^## Considered options$/i\
## Decision drivers\
\
- It is enough.\

/^## Pros and cons of the options$/i\
### Confirmation\
\
A test.\

$a\
\
## More information\
\
None.'
expect_finding 'a missing section' '/^### Reversal$/d' \
  "$((appended - 2)): section \"### Reversal\" missing"
second='/^### Reversal$/d' expect_finding \
  'a section missing from the next record only' '' \
  "2-do-one-thing.md:$((appended - 2)): section \"### Reversal\" missing"
expect_finding 'two sections swapped' \
  's/^## Context and problem statement$/## Swap/
s/^## Considered options$/## Context and problem statement/
s/^## Swap$/## Considered options/' \
  '17: section "## Context and problem statement" comes after "## Considered'
expect_finding 'a subsection outside its section' \
  "/^### Consequences\$/d"$'\n'"$(append '' '### Consequences')" \
  "${appended}: section \"### Consequences\" comes after \"## Pros and cons"
expect_finding 'a section at the wrong level' \
  's/^## Decision outcome$/### Decision outcome/' \
  '22: "### Decision outcome" should be "## Decision outcome"'

finish
