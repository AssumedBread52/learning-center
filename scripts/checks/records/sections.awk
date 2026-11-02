# Reports each required section a record is missing, holds at the wrong
# heading level, or holds out of the contract's order. Other headings are
# not judged.
BEGIN {
  count = split("## Context and problem statement|## Considered options|" \
    "## Decision outcome|### Consequences|### Reversal|" \
    "## Pros and cons of the options", required, "|")
  for (i = 1; i <= count; i++) {
    name = required[i]
    sub(/^#+ /, "", name)
    order[name] = i
  }
}
function report(line, message) {
  print file ":" line ": " message
  found = 1
}
function finish(  i) {
  if (file == "") return
  for (i = 1; i <= count; i++)
    if (!(i in seen))
      report(lines, "section \"" required[i] "\" missing")
}
FNR == 1 {
  finish()
  file = FILENAME
  last = 0
  split("", seen)
}
{
  lines = FNR
}
/^#+ / {
  name = $0
  sub(/^#+ /, "", name)
  if (!(name in order)) next
  i = order[name]
  seen[i] = 1
  if ($0 != required[i])
    report(FNR, "\"" $0 "\" should be \"" required[i] "\"")
  if (i < last)
    report(FNR, "section \"" required[i] "\" comes after \"" \
      required[last] "\"")
  else
    last = i
}
END {
  finish()
  exit found
}
