# Reports each record whose first line after the front matter is not the
# heading "# ADR-N: title", with N from the file name and the title from the
# front matter. A record whose front matter is missing or never closed is
# left to front-matter.awk.
function report(line, message) {
  print file ":" line ": " message
  found = 1
}
function number(  name) {
  name = file
  sub(/.*\//, "", name)
  sub(/-.*/, "", name)
  return name
}
function finish() {
  if (state == "body")
    report(closing, "heading missing; expected \"" expected "\"")
}
FNR == 1 {
  finish()
  file = FILENAME
  title = ""
  state = ($0 == "---") ? "open" : "done"
  next
}
state == "open" && /^title: ?/ {
  title = $0
  sub(/^title: ?/, "", title)
  next
}
state == "open" && $0 == "---" {
  state = "body"
  closing = FNR
  expected = "# ADR-" number() ": " title
  next
}
state == "body" && $0 != "" {
  if ($0 != expected)
    report(FNR, "heading \"" $0 "\" is not \"" expected "\"")
  state = "done"
}
END {
  finish()
  exit found
}
