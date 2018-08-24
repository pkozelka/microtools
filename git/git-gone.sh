git branch -v| sed -n '/^  .* [0-9a-f]\{10\} \[gone\] /{s:  \([^[:space:]]*\) .*:\1:;p;}'
