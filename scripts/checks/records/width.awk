# Reports each line of prose wider than 80 columns; headings, table rows,
# the title field, and lines carrying a URL are exempt, since they cannot
# wrap.
BEGIN {
  width = 80
}
function exempt(text) {
  return text ~ /^(#|\||title: )/ || text ~ /https?:\/\//
}
length($0) > width && !exempt($0) {
  print FILENAME ":" FNR ": " length($0) " columns; prose wraps at " width
  found = 1
}
END {
  exit found
}
