#!/bin/bash
#
# Simple utility to replicate all received files from one (local) nexus instance to another (remote).
# 2016 (C) Petr Kozelka
#

#
# Usage in cron job:
# 1 * * * * while true; do cd /sonatype-work/storage && ~/bin/sync-dir-to-nexus.sh --dir $PWD/releases --url https://nexus.cz.infra/nexus/service/local/repositories/releases/content >releases/.console.txt 2>&1; done
#


function log() {
    echo "$@"
    echo "$@" >>$LOGFILE
}

##
# Find files newer than last modification of the logfile
#
function findNewerFiles() {
    find $LOCAL_DIR/* -newer $LOGFILE -type f -printf 'resync %p\n'
}

##
# Verify recently created files by contacting remote party
#
function verifyRecent() {
    local minutes="${1-'60'}"
    touch "$LOCAL_DIR/.verified"
    echo "Verifying $LOCAL_DIR for changes in last $minutes minutes"
    find $LOCAL_DIR -ctime "-${minutes}" -type f -printf '%P\n' | while read uri; do
        verifyUri "$uri"
    done
}

##
# Watch infinitely for changes in local directory
#
function watchLoop() {
    inotifywait -q -m -r \
      -e close_write,delete,moved_to,moved_from \
      --format '%e %w%f' \
      @$LOGFILE \
      "$LOCAL_DIR" "$MYSELF"
}

##
# Verifies that given file is really uploaded by querying the remote side.
# Files that were once verified will not be verified again.
#
function verifyUri() {
    local uri="$1"
    [ "${uri:0:1}" == '.' ] && return 0
    shift
#    echo "Verifying '$uri'"
    # remote verification is expensive - do not do that twice
    grep -q '^'"$uri"'$' "$LOCAL_DIR/.verified" && return 0

    # not yet verified
    local http_code=$($CURL -L --head \
      "$@" "$REMOTE_URL/$uri" \
      -s --output "$LOCAL_DIR/.head.curl" \
      --write-out "%{http_code}" \
      2>/dev/null) || return 1

#    echo "$CURL ::: <$uri>: $http_code"

    local filename="$LOCAL_DIR/$uri"
    case "$http_code" in
    4??) # NOT FOUND
        nexusCurl "A" "$uri" --upload-file "$filename" || return 1
        echo "$uri" >>"$LOCAL_DIR/.verified"
        ;;
    2??)
        echo "$uri" >>"$LOCAL_DIR/.verified"
        ;; # FOUND
    *) # other / problem
        echo "$http_code $uri" >&2
        return 1;;
    esac
    return 0
}

function nexusCurl() {
    local actionCode=$1
    local uri=$2
    shift 2
    $CURL "$@" "$REMOTE_URL/$uri" \
        --output "$LOCAL_DIR/.curl" \
        --write-out "%{http_code}" > "$LOCAL_DIR/.curl.code" \
        -v 2>"$LOCAL_DIR/.curl.stderr" || return 1
    local http_code=$(cat "$LOCAL_DIR/.curl.code")
    case "$http_code" in
    2??)
        log "$actionCode $http_code $uri"
        return 0
        ;;
    *)
        echo "ERROR: $actionCode $http_code $REMOTE_URL/$uri" >&2
        cat "$LOCAL_DIR/.curl" >&2
        return 1
        ;;
    esac
}

function syncToNexus() {
    local events filename
    while read events filename; do
        # inotify exclusion doesn't seem to work
        case "$filename" in
        "$LOGFILE") continue;;
        "$LOCAL_DIR/."*) continue;;
        "$CONFIG")
            printf "WARNING: Configuration changed (%s), aborting\n" $(md5sum "$CONFIG" | cut -f1 -d' ') >&2
            kill $$
            exit 0;;
        "$MYSELF")
            printf "WARNING: Script changed (%s), aborting\n" $(md5sum "$MYSELF" | cut -f1 -d' ') >&2
            kill $$
            exit 0;;
#        *'.md5'|*'.sha1') continue;;
#        *'/maven-metadata.xml') continue;;
        esac
        #
        local uri=${filename:${#LOCAL_DIR}+1}
        case "$events" in
        'CLOSE_WRITE,CLOSE' | 'MOVED_TO' | 'resync')
            nexusCurl "A" "$uri" --upload-file "$filename" || continue
            ;;
        'DELETE' | 'DELETE,ISDIR' | 'MOVED_FROM')
            nexusCurl "D" "$uri" -X DELETE || continue
            ;;
        esac
    done
}

function checkSingletonLock() {
    local pidfile="$LOCAL_DIR/.pid"
    local pid
    [ -s "$pidfile" ] && pid=$(cat "$pidfile")
    local procName
    [ -n "$pid" ] && procName=$(ps -p "$pid" -o comm=)
    if [ -n "$procName" ]; then
        # already running, cannot lock
        printf "%s ERROR: already running with pid=%s\n" "$(date --iso-8601=sec)" "$pid"
        return 1
    fi
    # lock
    echo "$$" >"$pidfile"
}

#### MAIN

function doMain() {
    # parse options
    while [ "${1:0:2}" == '--' ]; do
        local option="$1"
        shift
        case "$option" in
        '--config')
            CONFIG="$1"
            shift
            eval $(cat "$CONFIG") || return 1
            ;;
        '--dir')
            LOCAL_DIR="$1"
            shift
            ;;
        '--user')
            CURL_AUTH="-u $1"
            shift
            ;;
        '--url')
            REMOTE_URL=$1
            shift
            ;;
        '--'*)
            echo "ERROR: Unknown option: $option" >&2
            ;;
        *) break;;
        esac
    done

    MYSELF="$0"

    case "$REMOTE_URL" in
    'https://'*) CURL="$CURL -k";;
    esac

    echo "Syncing $LOCAL_DIR to $REMOTE_URL"
    local commands="$*"
    [ -z "$commands" ] && commands="findNewer verifyRecent lock watch"
    local command
    for command in $commands; do
        case "$command" in
        'findNewer')
            findNewerFiles | syncToNexus
            ;;
        'verifyRecent')
            verifyRecent "120"
            ;;
        'lock') # DO NOT RUN TWICE on the same dir
            checkSingletonLock || return 1
            ;;
        'watch')
            watchLoop | syncToNexus
            ;;
        *) echo "ERROR: Unknown command: '$command'"
        esac
    done
    local pidfile="$LOCAL_DIR/.pid"
    rm -f "$pidfile"
    return 0
}

# Configuration defaults
CURL_AUTH="-u deployment:deployment123"
REMOTE_URL="http://localhost:8081/service/local/repositories/releases/content"
LOCAL_DIR="$PWD"

# Override defaults with default configuration, if present
CONFIG="$PWD/sync-dir-to-nexus.config"
[ -s "$CONFIG" ] && eval $(cat "$CONFIG")
[ -z "$LOGFILE"] && LOGFILE="$LOCAL_DIR/.nexus-sync.log"

# globals
CURL="curl $CURL_AUTH"
doMain "$@"
