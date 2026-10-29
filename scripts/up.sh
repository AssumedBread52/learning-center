#!/usr/bin/env bash
# Brings the stack up (ADR-4): ensures on the host what Compose needs
# before it can parse compose.yaml, then runs docker compose up. Each
# ensured item follows one rule: missing, generate it; present, leave
# it, stopping only when a value that must match the host does not;
# never destroy. Today that is the git-ignored .env, for which this
# script is the template, and core.hooksPath (ADR-3). Image versions
# are not among them: they are committed in compose.yaml. Bash,
# coreutils, git, and docker only.
set -euo pipefail

HOOKS_DIRECTORY='.githooks'

# Prints how to call the script and what it writes.
usage() {
  cat <<USAGE
Usage: scripts/up.sh [--help] [--no-up] [docker compose up options]

Ensures <repository>/.env has these keys, adding only missing ones:
  USER_ID, GROUP_ID     from id -u and id -g, so bind-mounted files
                        belong to you; another value stops the script
  COMPOSE_PROJECT_NAME  learning-center- plus the directory's name, so
                        production/ and development/ run side by side
Inside a git repository it also sets core.hooksPath to ${HOOKS_DIRECTORY}
when unset, and warns when it is set to something else.
Then runs docker compose up --pull missing with the remaining options,
unless --no-up. Safe to run any number of times.
USAGE
}

# Resolves the repository root from this script's own location, so the
# script works from any working directory.
repository_root() {
  cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P
}

# Turns a directory name into a Compose project name: lowercase letters,
# digits, dashes, and underscores, starting with a letter or digit.
project_name() {
  local name
  name=learning-center-$(basename "$1" | tr '[:upper:]' '[:lower:]' \
    | sed -E 's/[^a-z0-9_-]+/-/g; s/^[^a-z0-9]+//')
  printf '%s' "${name%-}"
}

# Creates the file with a one-line header when it does not exist, and
# ends an existing file with a newline when it lacks one, so that an
# appended key starts on a line of its own.
ensure_file() {
  local file=$1
  if [ ! -e "$file" ]; then
    echo '# From scripts/up.sh; git-ignored; reruns add only missing keys.' \
      > "$file"
    echo "created ${file}"
  elif [ -s "$file" ] && [ "$(tail -c 1 "$file")" != '' ]; then
    echo >> "$file"
  fi
}

# Appends KEY=VALUE to the file unless a line already sets KEY, and
# reports which happened. Never changes an existing line.
ensure_key() {
  local file=$1 key=$2 value=$3
  if grep -q "^${key}=" "$file"; then
    echo "kept  $(grep -m 1 "^${key}=" "$file")"
    return
  fi
  printf '%s=%s\n' "$key" "$value" >> "$file"
  echo "added ${key}=${value}"
}

# Like ensure_key, for a key whose value is a fact about the host: a
# line with another value stops the script, since files would land owned
# by someone else, and the message names the line to delete.
ensure_host_key() {
  local file=$1 key=$2 value=$3 line
  line=$(grep -m 1 "^${key}=" "$file" || true)
  if [ -n "$line" ] && [ "$line" != "${key}=${value}" ]; then
    echo "${file}: ${line} is not this host's ${value};" \
      'delete the line and rerun' >&2
    exit 1
  fi
  ensure_key "$file" "$key" "$value"
}

# Sets core.hooksPath only when the root is the top of a git work tree
# and the path is unset, so a copy sitting inside another repository and
# a path the developer chose are left untouched.
configure_hooks() {
  local root=$1 top current
  top=$(git -C "$root" rev-parse --show-toplevel 2> /dev/null || true)
  if [ "$top" != "$root" ]; then
    echo 'not a git repository root: core.hooksPath left unset;' \
      'rerun after cloning'
    return
  fi
  current=$(git -C "$root" config --get core.hooksPath || true)
  if [ "$current" = "$HOOKS_DIRECTORY" ]; then
    echo "kept  core.hooksPath=${HOOKS_DIRECTORY}"
    return
  fi
  if [ -n "$current" ]; then
    echo "warn  core.hooksPath=${current} left as set; the hooks in" \
      "${HOOKS_DIRECTORY} (ADR-3) will not run" >&2
    return
  fi
  git -C "$root" config core.hooksPath "$HOOKS_DIRECTORY"
  echo "set   core.hooksPath=${HOOKS_DIRECTORY}"
}

# Brings the stack up from the repository root, pulling only images
# that are not yet present; extra arguments go to docker compose up.
# Succeeds without starting anything while every service sits under a
# profile, which is the case until the application has services.
bring_up() {
  local root=$1; shift
  local services
  services=$(docker compose --project-directory "$root" config --services)
  if [ -z "$services" ]; then
    echo 'no services outside a profile yet: nothing to bring up'
    return
  fi
  docker compose --project-directory "$root" up --pull missing "$@"
}

main() {
  if [ "${1:-}" = '-h' ] || [ "${1:-}" = '--help' ]; then usage; exit 0; fi
  local up=true
  if [ "${1:-}" = '--no-up' ]; then up=false; shift; fi
  local root env_file
  root=$(repository_root)
  env_file="${root}/.env"
  ensure_file "$env_file"
  ensure_host_key "$env_file" USER_ID "$(id -u)"
  ensure_host_key "$env_file" GROUP_ID "$(id -g)"
  ensure_key "$env_file" COMPOSE_PROJECT_NAME "$(project_name "$root")"
  configure_hooks "$root"
  if [ "$up" = true ]; then bring_up "$root" "$@"; fi
}

main "$@"
