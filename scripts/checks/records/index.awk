# Reports each row of the index in the README.md beside the records that
# differs from the row a record's file name and front matter call for, is
# missing, has no record, or is out of number order. Rows are matched by
# their first cell, "[N](file)".
function report(line, message) {
  print readme ":" line ": " message
  found = 1
}
function first_cell(row) {
  sub(/^\| /, "", row)
  sub(/ \|.*/, "", row)
  return row
}
function expected(key) {
  return "| " key " | " values[key, "title"] " | " values[key, "area"] \
    " | " values[key, "status"] " |"
}
FNR == 1 {
  name = FILENAME
  sub(/.*\//, "", name)
  key = "[" substr(name, 1, index(name, "-") - 1) "](" name ")"
  keys[++count] = key
  position[key] = count
  readme = FILENAME
  sub(/[^\/]*$/, "", readme)
  readme = readme "README.md"
}
/^(title|area|status): ?/ {
  field = $0
  sub(/:.*/, "", field)
  value = $0
  sub(/^[^:]*: ?/, "", value)
  if (!((key, field) in values)) values[key, field] = value
}
END {
  if (count == 0) exit 0
  while ((getline line < readme) > 0) {
    lines++
    if (line ~ /^## /) inside = (line == "## Index")
    if (!inside || line !~ /^\| \[/) continue
    row = first_cell(line)
    if (!(row in position)) {
      report(lines, "index row \"" line "\" has no record")
      continue
    }
    rows[row] = line
    at[row] = lines
    if (position[row] < previous)
      report(lines, "index row for \"" row "\" comes after \"" \
        keys[previous] "\"")
    else
      previous = position[row]
  }
  for (i = 1; i <= count; i++) {
    row = keys[i]
    if (!(row in rows))
      report(lines ? lines : 1, "index has no row for \"" row "\"")
    else if (rows[row] != expected(row))
      report(at[row], "index row \"" rows[row] "\" should be \"" \
        expected(row) "\"")
  }
  exit found
}
