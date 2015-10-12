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

function rawToJson() {
    while read key value; do
        case "key" in
        'commit') echo '    "commit": "'$key'",';;
        'tree') echo '    "tree": "'$key'",';;
        'parent') echo '    "parent": "'$key'",';;
        'author') echo '    "author": "'$key'",';;
        'committer') echo '    "committer": "'$key'",';;
        *) break;;
        esac
    done
}

function toJson() {
    local hash=$1
    git show --pretty=raw | rawToJson
}

git rev-list --parents HEAD | filterMainLine


