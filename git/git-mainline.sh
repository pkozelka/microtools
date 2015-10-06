#!/bin/bash
#
# Follow main line of the commits between two revs
# The purpose is to gather docs, consisting of both merge requests AND direct commits
#

function filterMainLine() {
    local hash parentHash
    read hash parentHash other || return 1
    while [ -n "$hash" ]
    do
        echo "$hash"
        local firstParent="$parentHash"
        # skip until we find hash==firstParent
        read hash parentHash other || return 1
        local skipCnt=0
        while [ "$hash" != "$firstParent" ]
        do
            skipCnt=$(( skipCnt + 1 ))
#            printf "... skipping %3d: %s (not %s)\n" "$skipCnt" "$hash" "$firstParent"
            read hash parentHash other || return 1
        done
    done
}

git rev-list --parents HEAD | filterMainLine
