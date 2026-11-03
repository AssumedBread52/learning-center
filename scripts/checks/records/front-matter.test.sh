#!/usr/bin/env bash
# Tests of front-matter.awk, through records.sh.
set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/testing.sh"

expect_clean 'a valid record' ''
expect_clean 'a superseded record' \
  "$(field status 'Superseded by ADR-2'); $(field superseded_by ADR-2)"

expect_finding 'no front matter' '1d' '1: front matter missing'
expect_finding 'an unclosed front matter' '9d' \
  '1-do-one-thing.md:1: front matter is never closed'

expected='expected "title status date area trigger supersedes superseded_by"'
expect_finding 'fields out of order' '/^area:/{h;d;}; /^trigger:/G' \
  'are "title status date trigger area supersedes superseded_by"'
expect_finding 'a missing field' '/^trigger:/d' "$expected"
expect_finding 'an unknown field' '/^area:/a\
foo: bar' "$expected"
expect_absent 'an unknown field judged as a value' '/^area:/a\
foo: bar' 'foo "bar"'

expect_finding 'an empty title' "$(field title '')" '2: title "" is not'
expect_finding 'a draft status' "$(field status Draft)" 'status "Draft"'
expect_finding 'a date in another form' "$(field date 29/10/2026)" \
  'date "29/10/2026"'
expect_finding 'an area not in kebab case' "$(field area Process)" \
  'area "Process"'
expect_finding 'a trigger outside the set' "$(field trigger maybe)" \
  'trigger "maybe"'
expect_finding 'a padded supersedes' "$(field supersedes ADR-02)" \
  'supersedes "ADR-02"'
expect_finding 'a bare superseded_by' "$(field superseded_by 2)" \
  'superseded_by "2"'

finish
