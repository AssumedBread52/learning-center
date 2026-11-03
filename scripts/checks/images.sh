#!/usr/bin/env bash
# Checks the images of a repository, the current directory by default,
# against ADR-4 and ADR-5: no image recipe among the files git tracks, and
# at least one image, each image Compose resolves in every profile named by
# a MAJOR.MINOR.PATCH tag and nothing else. Prints one finding per line and
# exits 1 when there is any.
set -euo pipefail

main() {
  local directory=${1:-.} status=0
  recipes "$directory" || status=1
  tags "$directory" || status=1
  exit "$status"
}

# Reports each Dockerfile, *.Dockerfile, or Containerfile git tracks.
recipes() {
  local found
  found=$(git -C "$1" ls-files |
    grep -E '(^|/)(([^/]*\.)?Dockerfile|Containerfile)$') || return 0
  printf '%s\n' "$found" |
    sed 's/$/: an image recipe; images are published ones (ADR-4)/'
  return 1
}

# Reports each image not named by a MAJOR.MINOR.PATCH tag, or no image at
# all. The user ids only satisfy compose.yaml; no image depends on them.
tags() {
  USER_ID=0 GROUP_ID=0 docker compose --file "$1/compose.yaml" \
    --profile '*' config --images |
    awk '
      $0 !~ /^[a-z0-9][a-z0-9._\/-]*:[0-9]+\.[0-9]+\.[0-9]+$/ {
        print "compose.yaml: image \"" $0 "\" is not named by a " \
          "MAJOR.MINOR.PATCH tag"
        found = 1
      }
      END {
        if (NR == 0) print "compose.yaml: no images resolved"
        exit found || NR == 0
      }'
}

main "$@"
