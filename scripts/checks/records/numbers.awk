# Reports each record whose number, from its file name, an earlier record
# already has (the contract's Numbering bullet).
FNR == 1 {
  name = FILENAME
  sub(/.*\//, "", name)
  number = substr(name, 1, index(name, "-") - 1)
  if (number in first) {
    print FILENAME ":1: number " number " is already used by " first[number]
    found = 1
  } else {
    first[number] = name
  }
}
END {
  exit found
}
