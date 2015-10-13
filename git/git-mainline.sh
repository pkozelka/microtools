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
        case "$key" in
        'commit'|'tree')
            echo '    "'"$key"'": "'$value'",'
            ;;
        'author'|'committer')
            #convert datetime to iso: date -d 'TZ="+0200" @1444490433' --iso-8601=sec
            echo '    "'"$key"'": "'$value'",'
            ;;
        'parent')
            #TODO other parents will be rendered as array "merged"
            echo '    "parent": "'$value'",'
            ;;
        *) break;;
        esac
#TODO now parse message as array of lines
    done
}

function toJson() {
    local hash=$1
    echo "  hash: $hash; object: {"
    git show -s --pretty=raw "$hash" | rawToJson
    echo "  },"
}

function xxargs() {
    while read
    do
        "$@" "$REPLY"
    done
}

git rev-list --parents HEAD | head | filterMainLine | xxargs toJson


