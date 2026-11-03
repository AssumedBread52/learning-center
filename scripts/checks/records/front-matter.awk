# Reports each record whose front matter is missing, never closed, out of
# order, or holding a value the contract does not allow.
BEGIN {
  fields = "title status date area trigger supersedes superseded_by"
  record = "ADR-[1-9][0-9]*"
}
function report(line, message) {
  print FILENAME ":" line ": " message
  found = 1
}
function allowed(key, value) {
  if (key == "title") return value != ""
  if (key == "status")
    return value ~ "^(Implementing|Implemented|Superseded by " record ")$"
  if (key == "date")
    return value ~ /^[0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]$/
  if (key == "area") return value ~ /^[a-z][a-z0-9-]*$/
  if (key == "trigger") return value ~ /^(observed|deliberate|none)$/
  if (key == "supersedes" || key == "superseded_by")
    return value ~ "^(none|" record ")$"
  return 1
}
function finish() {
  if (state != "open") return
  print file ":1: front matter is never closed"
  found = 1
}
FNR == 1 {
  finish()
  file = FILENAME
  keys = ""
  state = ($0 == "---") ? "open" : "body"
  if (state == "body")
    report(1, "front matter missing: the first line must be ---")
  next
}
state == "open" && $0 == "---" {
  seen = substr(keys, 2)
  if (seen != fields)
    report(FNR, "front matter fields are \"" seen "\"; expected \"" \
      fields "\"")
  state = "body"
  next
}
state == "open" && $0 !~ /^[a-z_]+: ?/ {
  report(1, "front matter is never closed")
  state = "body"
}
state == "open" {
  key = $0; sub(/:.*/, "", key)
  value = $0; sub(/^[^:]*: */, "", value)
  keys = keys " " key
  if (!allowed(key, value))
    report(FNR, key " \"" value "\" is not allowed by the contract")
}
END {
  finish()
  exit found
}
