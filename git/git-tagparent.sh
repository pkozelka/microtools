#!/bin/bash
#
# Finds all tags matching a pattern, and tags its parent with similar tag name (using given prefix).
# Useful when releases are tagged in side branches.
#

function markTagParent() {
    local findPattern=${1?'specify tag prefix'}
    local addPrefix=${2-'RELEASE-'}

    for tag in $(git tag -l "${findPattern}"); do
        local parent=$(git rev-list --max-count=2 $tag | tail -1)
        git tag "${addPrefix}${tag}" "$parent"
    done
}

markTagParent "$@"
