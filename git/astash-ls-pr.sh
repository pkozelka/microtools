#!/bin/bash
# list pull request from an Atlassian Stash git repo

function findPulls() {
	git log --pretty=oneline | sed -n '/ Merge pull request #/{s:^\([^ ]*\) Merge pull request #\([0-9]*\) in \([^ ]*\) from \([^ ]*\) to \([^ ]*\)$:\1 \2 \3 \4 \5:;p;}' | while read rev pr project from to
	do
		echo "$rev #$pr $project: $from --> $to"
	done
}

findPulls
