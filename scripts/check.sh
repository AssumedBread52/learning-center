#!/usr/bin/env bash
# Runs every check in scripts/checks/ of a repository, the current one by
# default, in name order and all of them even after one fails: the one list
# the pre-commit hook (ADR-5) and the hosted check (ADR-6) both run. The
# hosted check sets CHECK_RANGE=BASE..HEAD to the commits under check, and
# the checks inherit it. Names the failing checks and exits 1 when any
# failed.
set -uo pipefail

main() {
  local root check failed=()
  root=${1:-$(git rev-parse --show-toplevel)}
  cd "$root" || exit 1
  for check in scripts/checks/*.sh; do
    bash "$check" || failed+=("$check")
  done
  if [ "${#failed[@]}" -gt 0 ]; then
    echo "check: failing checks: ${failed[*]}" >&2
    exit 1
  fi
}

main "$@"
