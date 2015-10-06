#!/bin/bash
#
# Follow main line of the commits between two revs
# The purpose is to gather docs, consisting of both merge requests AND direct commits
#
# TODO ::: not working yet

function filterMainLine() {
    local hash parentHash
    read hash parentHash
    while [ -n "$hash" ]
    do
        echo "$hash"
        local firstParent="$parentHash"
        # skip until we find hash==firstParent
        while [ "$hash" != "$firstParent" ]
        do
            read hash parentHash || break
        done
    done
}

git rev-list --parents HEAD | filterMainLine
