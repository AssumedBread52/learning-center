#!/usr/bin/env bash
# Checks that each record a commit adds to docs/adr, in a repository that
# is the current directory by default, carries the entry day as its date
# (ADR-1), reading the staged content. Today is the local day, the day git
# stamps on the commit. Prints one finding per line and exits 1 when there
# is any.
set -euo pipefail

main() {
  local directory=${1:-.} today record date status=0
  today=$(date +%Y-%m-%d)
  while IFS= read -r record; do
    date=$(git -C "$directory" show ":$record" | sed -n '/^date: /{s///p;q;}')
    if [ "$date" != "$today" ]; then
      echo "${record}: date ${date} is not the entry day ${today}"
      status=1
    fi
  done < <(added_records "$directory")
  exit "$status"
}

# Prints the path of each record the index adds, the template excepted.
added_records() {
  git -C "$1" diff --cached --name-only --diff-filter=A -- \
    ':(glob)docs/adr/[1-9]*.md'
}

main "$@"
