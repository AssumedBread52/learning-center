#!/usr/bin/env bash
# Checks the message of every commit after BASE up to HEAD with the
# commit-msg hook (ADR-3, ADR-5), for the hosted check (ADR-6), which sees
# commits the client's hook never met. Run from the repository root; the
# hook prints each finding, and this script exits 1 when any commit fails.
set -euo pipefail

main() {
  local base=$1 head=$2 commit status=0
  local message="${TMPDIR:-/tmp}/headers.$$"
  trap 'rm -f "$message"' EXIT
  for commit in $(git rev-list --reverse "${base}..${head}"); do
    git log -1 --format=%B "$commit" > "$message"
    if ! bash .githooks/commit-msg "$message"; then
      echo "  in commit ${commit}" >&2
      status=1
    fi
  done
  exit "$status"
}

main "$@"
