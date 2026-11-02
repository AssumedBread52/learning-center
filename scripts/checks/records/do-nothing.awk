# Reports each record whose pros and cons of the options hold no
# "### Option K: Do nothing" subsection. A record without that section is
# left to sections.awk.
function report(line, message) {
  print file ":" line ": " message
  found = 1
}
function finish() {
  if (state == "pros")
    report(start, "no \"### Option K: Do nothing\" under the pros and cons")
  state = "after"
}
FNR == 1 {
  finish()
  file = FILENAME
  state = "before"
}
$0 == "## Pros and cons of the options" {
  state = "pros"
  start = FNR
  next
}
state == "pros" && /^### Option [1-9][0-9]*: Do nothing$/ {
  state = "after"
}
state == "pros" && /^## / {
  finish()
}
END {
  finish()
  exit found
}
