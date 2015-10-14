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
    local parent=""
    local merges=""
    while read key value; do
        case "$key" in
        'commit'|'tree')
            printf '  "%s": "%s",\n' "$key" "$value"
            ;;
        'author'|'committer')
            #convert datetime to iso: date -d 'TZ="+0200" @1444490433' --iso-8601=sec
            printf '  "%s": "%s",\n' "$key" "$value"
            ;;
        'parent')
            if [ -z "$parent" ]; then
                #TODO other parents will be rendered as array "merged"
                parent="$value"
            else
                merges="$value "
            fi
            ;;
        '') break;;
        esac
    done
# end of key/value pairs; now comes message, but first render parents
    [ -n "$parent" ] && printf '  "parent": "%s"\n' "$parent"
    if [ -n "$merges" ]; then
        local m
        local first="true"
        printf '  "merges": ['
        for m in $merges; do
            "$first" || printf ","
            first="false"
            printf '"%s"' "$m"
        done
        printf ']\n'
    fi
    # parse message - each line is prefixed with 4 spaces
    printf '  "message": [\n'
    local first="true"
    while read; do
        case "$REPLY" in
        '    '*)
            local line=${REPLY:4}
            "$first" || printf ",\n"
            first="false"
            printf '    "%s"' "$line"
            ;;
        '') break;;
        esac
    done
    printf ']\n'
}

function toJson() {
    local hash=$1
    printf "{\n"
    git show -s --pretty=raw "$hash" | rawToJson
    printf "},"
}

function xxargs() {
    while read
    do
        "$@" "$REPLY"
    done
}

printf "["
git rev-list --parents HEAD | head | filterMainLine | xxargs toJson
printf "null]"


