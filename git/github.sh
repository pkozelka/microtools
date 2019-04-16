#!/bin/bash

# https://developer.github.com/v3/repos/statuses/

function showUser() {
$CURL/user
}


function listStatuses() {
    $CURL_AA/commits/$HASH/statuses
}

function deleteStatus() {
    local id=$1
    $CURL_AA/commits/$HASH/statuses
}

function setStatus() {
    local status=$1
    local context=$2
    local desc=$3
$CURL_AA/statuses/${HASH} -d@- <<EOF
{
  "state": "$status",
  "target_url": "https://example.com",
  "description": "$desc",
  "context": "$context"
}
EOF
}

function createPullRequestComment() {
    local id=$1
    local text=$2
$CURL_AA/pulls/$id/comments -d@- <<EOF
{
  "body": "$text",
  "commit_id": "$HASH",
  "path": "file1.txt",
  "position": 4
}
EOF
}

function createIssueComment() {
    local id=$1
    local text=$2
$CURL_AA/issues/$id/comments -d@- <<EOF
{
  "body": "$text"
}
EOF
}

function showStatuses() {
$CURL_AA/commits/$HASH/statuses
}


##
# show github domain and repo
#
function showInfo() {
    local remoteOriginUrl=$(git config "remote.origin.url")
    case "$remoteOriginUrl" in
    'git@github'*:*.git)
        local s=${remoteOriginUrl/#git@/}
        local domain=${s%:*}
        local s=${s/#*:/}
        local repo=${s%.git}
        echo -e "${domain}\t${repo}"
        ;;
    *) echo "ERROR: not a github url scheme" >&2; return 1;;
    esac
}

#$CURL_AA/commits/$HASH/statuses

# setStatus "$@"

#createIssueComment "$@"
#createPullRequestComment "$@"

#### MAIN ####

HASH=$(git rev-parse HEAD)
# -H "Authorization: token $TOKEN" 
INFO=( $(showInfo) )

CURL="curl -v -n https://${INFO[0]}/api/v3"
CURL_AA=$CURL/repos/${INFO[1]}

 cmd=$1
shift

case "$cmd" in
r) showInfo;;
st) listStatuses "$@";;
std) deleteStatus "$@";;
sts) setStatus "$@";;
*) echo "ERROR: Unknown command: $cmd" >&2; exit 1;;
esac
