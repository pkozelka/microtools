#!/bin/bash
A=${1?}
B=${2?}
git log --name-only --pretty=oneline --full-index $A..$B | grep -vE '^[0-9a-f]{40} ' | sort -u | while read f; do
	[ -e "$f" ] && echo "$f"
done
