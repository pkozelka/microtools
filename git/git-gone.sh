git branch -v --no-abbrev | sed -n '/^  .* [0-9a-f]\{40\} \[gone\] /{s:  \([^[:space:]]*\) .*:\1:;p;}'
