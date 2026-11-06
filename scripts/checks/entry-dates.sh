#!/usr/bin/env bash
# Checks that each record added to docs/adr, in a repository that is the
# current directory by default, carries as its date the day of the commit
# that adds it (ADR-1). Without CHECK_RANGE that commit is the one being
# made (ADR-5): the records the index adds, against today, the local day
# git stamps on it. With CHECK_RANGE=BASE..HEAD the commits exist (ADR-6):
# the records each one adds, against its author day. Prints one finding
# per line and exits 1 when there is any.
set -euo pipefail

readonly RECORDS=':(glob)docs/adr/[1-9]*.md'

main() {
  local directory=${1:-.} object record day date status=0
  while IFS=$'\t' read -r object record day; do
    date=$(git -C "$directory" show "$object" | sed -n '/^date: /{s///p;q;}')
    if [ "$date" != "$day" ]; then
      echo "${record}: date ${date} is not the entry day ${day}"
      status=1
    fi
  done < <(added "$directory")
  exit "$status"
}

# Prints a row per added record, the template excepted: the object that
# holds it, its path, and its entry day, separated by tabs.
added() {
  if [ -n "${CHECK_RANGE:-}" ]; then committed "$1"; else staged "$1"; fi
}

staged() {
  local today record
  today=$(date +%Y-%m-%d)
  git -C "$1" diff --cached --name-only --diff-filter=A -- "$RECORDS" |
    while IFS= read -r record; do
      printf ':%s\t%s\t%s\n' "$record" "$record" "$today"
    done
}

committed() {
  local commit day record
  for commit in $(git -C "$1" rev-list --reverse "$CHECK_RANGE"); do
    day=$(git -C "$1" log -1 --format=%ad --date=short "$commit")
    git -C "$1" diff-tree --root --no-commit-id --name-only -r \
      --diff-filter=A "$commit" -- "$RECORDS" |
      while IFS= read -r record; do
        printf '%s:%s\t%s\t%s\n' "$commit" "$record" "$record" "$day"
      done
  done
}

main "$@"
