#!/bin/bash
# Extract given row from provided csv file and flatten it.
# Write output to the same name suffixed with row number and '.txt'

FILE=${1?'input file'}
ROW=${2-'0'}
OF="${FILE}.${ROW}.txt"

cat <<EOF >&2
FILE=$FILE
ROW=$ROW
OF=$OF
EOF

cat "$FILE" | xsv slice --start "$ROW" --len 1 | xsv flatten > "${OF}"
