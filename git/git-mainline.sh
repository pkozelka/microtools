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
            read hash parentHash other || return 1
        done
    done
}

function rawAuthorToJson() {
    local fullname=""
    local email=""
    while [ -n "$1" ]; do
        local token="$1"
        shift
        case "$token" in
        '<'*'>')
            printf '"email": "%s", ' "${token:1:${#token}-2}"
            break;;
        *) fullname="$fullname $token";;
        esac
    done
    printf '"name": "%s", ' "${fullname:1}"
    local time=$1
    local tz=$2
    printf '"time": "%s"' $(date --iso-8601=sec -d 'TZ="'"$tz"'" @'"$time")
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
            printf '  "%s": {' "$key"
            rawAuthorToJson $value
            printf '},\n'
            ;;
        'parent')
            if [ -z "$parent" ]; then
                parent="$value"
            else
                merges="$value "
            fi
            ;;
        '') break;;
        esac
    done
# end of key/value pairs; now comes message, but first render parents
    [ -n "$parent" ] && printf '  "parent": "%s",\n' "$parent"
    if [ -n "$merges" ]; then
        printf '  "merges": ['
        local m
        for m in $merges; do
            printf '"%s",' "$m"
        done
        printf 'REMOVE_TRAILING_COMMA],\n'
    fi
    # parse message - each line is prefixed with 4 spaces
    printf '  "message": ['
    while read; do
        case "$REPLY" in
        '    '*)
            local line=${REPLY:4}
            line=${line//\"/\\\"}
            line="${line//	/\\t}"
            printf '\n    "%s",' "$line"
            ;;
        '') break;;
        esac
    done
    printf 'REMOVE_TRAILING_COMMA]\n'
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

function printAllRevisions() {
    local repositoryUrl=$(git config "remote.origin.url")
    printf '{ "repository": "%s", "commits":[' "$repositoryUrl"
    git rev-list --parents HEAD | head -100 | filterMainLine | xxargs toJson
    # we must soon find a better way than null
    printf "REMOVE_TRAILING_COMMA]}"
}

function removeTrailingCommas() {
    sed 's:,\?REMOVE_TRAILING_COMMA::g'
}

printAllRevisions "$@" | removeTrailingCommas
