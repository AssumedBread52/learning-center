#!/usr/bin/env bash
# Tests of scripts/up.sh, the .env it ensures: each case copies up.sh into
# a throwaway directory holding the given .env, runs it with --no-up, and
# expects a message, an absent message, or a stop.
set -euo pipefail

# Unsets the variables a git hook exports, which name the index and
# repository of the commit under way, so that git in up.sh acts on the
# fixture and never on the commit.
forget_enclosing_repository() {
  unset $(git rev-parse --local-env-vars)
}

forget_enclosing_repository
up=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)/up.sh
fixtures="${TMPDIR:-/tmp}/up-test.$$"
trap 'rm -rf "$fixtures"' EXIT
user=$(id -u)
other=$((user + 1))
failures=0

# Writes the fixture with up.sh and, when given, a .env of the lines in $1;
# then runs up.sh --no-up, prints its output, and returns its status.
run_with() {
  rm -rf "$fixtures" && mkdir -p "$fixtures/scripts"
  cp "$up" "$fixtures/scripts/up.sh"
  if [ "$#" -gt 0 ]; then printf '%s\n' "$1" > "$fixtures/.env"; fi
  bash "$fixtures/scripts/up.sh" --no-up
}

fail() {
  echo "FAIL  $1"
  failures=$((failures + 1))
}

# Expects up.sh to succeed and print the message, and not the text in
# $absent when set.
expect_message() {
  local name=$1 message=$2 output
  shift 2
  if ! output=$(run_with "$@" 2>&1); then
    fail "${name}: expected success, got: ${output}"
  elif ! grep -qF -- "$message" <<< "$output"; then
    fail "${name}: expected \"${message}\", got: ${output}"
  elif [ -n "${absent:-}" ] && grep -qF -- "$absent" <<< "$output"; then
    fail "${name}: expected no \"${absent}\", got: ${output}"
  fi
}

expect_stop() {
  local name=$1 message=$2 output
  shift 2
  if output=$(run_with "$@" 2>&1); then
    fail "${name}: expected a stop, got: ${output}"
  elif ! grep -qF -- "$message" <<< "$output"; then
    fail "${name}: expected \"${message}\", got: ${output}"
  fi
}

mismatch="USER_ID=${other} is not this host's ${user}"

expect_message 'no .env' "added USER_ID=${user}"
expect_message 'a key already set' 'kept  COMPOSE_PROJECT_NAME=mine' \
  'COMPOSE_PROJECT_NAME=mine'
absent='=second' expect_message 'a key set twice reports the first' \
  'kept  COMPOSE_PROJECT_NAME=first' \
  $'COMPOSE_PROJECT_NAME=first\nCOMPOSE_PROJECT_NAME=second'
expect_stop 'a host key of another host' "$mismatch" "USER_ID=${other}"
expect_stop 'a host key set twice, the first wrong' "$mismatch" \
  $"USER_ID=${other}"$'\n'"USER_ID=${user}"
expect_message 'a host key set twice, the first right' \
  "kept  USER_ID=${user}" $"USER_ID=${user}"$'\n'"USER_ID=${other}"

if [ "$failures" -gt 0 ]; then exit 1; fi
