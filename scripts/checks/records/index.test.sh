#!/usr/bin/env bash
# Tests of index.awk, through records.sh.
set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/testing.sh"

row1='| [1](1-do-one-thing.md) | Do one thing | process | Implementing |'
row2='| [2](2-do-one-thing.md) | Do one thing | process | Implementing |'
row3='| [3](3-do-it.md) | Do it | process | Implementing |'

expect_clean 'a retitled and superseded record with its row' \
  "$(title 'Do two things'); $(field status 'Superseded by ADR-2')
$(field superseded_by ADR-2)"
expect_clean 'a field-like line in the body' "$(append '' 'status: Draft')"
readme="1i\\
## Elsewhere\\
\\
${row3}\\
" expect_clean 'a row-like line outside the index' ''
readme='/\[1\]/s/Implementing/Implemented/' expect_finding 'a stale status' \
  '' "README.md:5: index row \"${row1/Implementing/Implemented}\" should be"
retitled=${row2/one thing/two things}
readme='/\[2\]/s/Do one thing/Do two things/' expect_finding \
  'a row with another title' '' \
  "README.md:6: index row \"${retitled}\" should be \"${row2}\""
readme='/\[2\]/d' expect_finding 'a missing row' '' \
  'README.md:5: index has no row for "[2](2-do-one-thing.md)"'
readme="\$a\\
${row3}" expect_finding 'a row without a record' '' \
  "README.md:7: index row \"${row3}\" has no record"
readme='5{h;d;}; 6G' expect_finding 'rows out of number order' '' \
  'README.md:6: index row for "[1](1-do-one-thing.md)" comes after "[2]'

finish
