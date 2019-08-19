#!/bin/bash

function listBranches() {
	git branch -v --no-abbrev | sed -n '/^  .* [0-9a-f]\{40\} \[gone\] /{s:  \([^[:space:]]*\) .*:\1:;p;}'
}

case "$1" in
'-d'|'--delete') listBranches | xargs -r git branch --delete;;
'-D') listBranches | xargs -r git branch --delete --force;;
'-p') git fetch --prune && listBranches | xargs -r git branch --delete;;
'-P') git fetch --prune && listBranches | xargs -r git branch --delete --force;;
'') listBranches;;
*) echo "ERROR: Unsupported flag: $1" >&2; exit 1;;
esac
