#!/bin/bash
# 2023 (C) Petr Kozelka

# Client script for invoking workflows.
# Matches the Github api as documented at https://docs.github.com/en/rest/actions/workflows?apiVersion=2022-11-28#create-a-workflow-dispatch-event

# Usage:
#   ./workflow-dispatch.sh <GITHUB_REPO> <WORKFLOW_ID> [--ref <REF>] [<INPUT_NAME>=<INPUT_VALUE>]...
# where
#   GITHUB_REPO is in form OWNER/REPO
#   WORKFLOW_ID is the workflow script name, or its numerical representation
#   REF indicates git branch or tag related to the execution
#   INPUT_NAME,INPUT_VALUE represent value assignments; their list must match the target workflow script
#
# Exit code 0 indicates that the script was successfully invoked; this is slightly unreliable, see description of `--fail` option in `man curl`.
#

function runWorkflow() {
  local DISPATCH_URL_BASE=${1?}
  local data=${2?}
  curl --fail \
    -H "Accept: application/vnd.github+json" \
    -H "Authorization: Bearer $GITHUB_TOKEN" \
    -H "X-GitHub-Api-Version: 2022-11-28" \
    --request POST \
    "$DISPATCH_URL_BASE/dispatches" \
    -d "$data"
}

#### MAIN ####

function main() {
  test -n "$GITHUB_TOKEN" || GITHUB_TOKEN=$(cat ~/.ssh/dispatch.github.token) # for local testing
  if [ -z "$GITHUB_TOKEN" ]; then
    echo "ERROR: missing GITHUB_TOKEN" >&2
    exit 1
  fi

  local GITHUB_REPO=${1?'Please specify github repo (OWNER/NAME) as the first argument'}
  shift
  case "$GITHUB_REPO" in
  */*);;
  *) echo "ERROR: This does not look like a github repo in format OWNER/NAME: '$GITHUB_REPO'" >&2; return 1;;
  esac
  local WORKFLOW_ID=${1?'Please specify workflow id or its file name as the second argument'}
  shift
  DISPATCH_URL_BASE="https://api.github.com/repos/$GITHUB_REPO/actions/workflows/$WORKFLOW_ID"

  local ref

  while [ "${1:0:2}" = "--" ]; do
    local opt=$1
    shift
    case "$opt" in
    '--ref') ref=$1; shift;;
    *) echo "ERROR: Invalid option '$opt'" >&2; return 1;;
    esac
  done
  test -n "$ref" || ref=$(git rev-parse --abbrev-ref HEAD)

  local inputs_json
  inputs_json=""
  while [ -n "${1}" ]; do
    local arg=$1
    shift
    case "$arg" in
    *=*);;
    *) echo "ERROR: Not an assignment: '$arg'" >&2; return 1;;
    esac
    local ij=${arg//\"/\\\"}
    ij=\"${ij//=/\": \"}\"
    inputs_json="$inputs_json, $ij"
  done
  inputs_json='{'"${inputs_json:1}"' }'
  local data="{ \"ref\": \"$ref\", \"inputs\": $inputs_json }"
  echo "DATA: $data"
  runWorkflow "$DISPATCH_URL_BASE" "$data"
}

main "$@"
