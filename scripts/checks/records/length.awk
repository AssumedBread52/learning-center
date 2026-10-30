# Reports each record longer than 150 lines, at the first line past the
# ceiling.
BEGIN {
  ceiling = 150
}
function finish() {
  if (lines <= ceiling) return
  print file ":" ceiling + 1 ": " lines " lines; the ceiling is " ceiling
  found = 1
}
FNR == 1 {
  finish()
  file = FILENAME
}
{
  lines = FNR
}
END {
  finish()
  exit found
}
