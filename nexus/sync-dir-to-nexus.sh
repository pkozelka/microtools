#!/bin/bash
#
# Simple utility to replicate all received files from one (local) nexus instance to another (remote).
# 2016 (C) Petr Kozelka
#

#
# Usage in cron job:
# 1 * * * * cd /sonatype-work/storage && ~/bin/sync-dir-to-nexus.sh --dir $PWD/releases --url https://nexus.cz.infra/nexus/service/local/repositories/releases/content >releases/.console.txt 2>&1
#

# Defaults for parameters
NEXUS_USER_PASS="deployment:deployment123"
NEXUS_CONTENT_URL="http://localhost:8081/service/local/repositories/releases/content"
LOCAL_DIR="$PWD"
#

function log() {
	echo "$@"
	echo "$@" >>$LOGFILE
}

function resyncDirectory() {
	find $LOCAL_DIR/* -newer $LOGFILE -type f -printf 'resync %p\n'
}

function monitorDirectory() {
	inotifywait -q -m -r \
		-e close_write,delete \
		--format '%e %w%f' \
		@$LOGFILE \
		"$LOCAL_DIR"
}

function nexusCurl() {
	local actionCode=$1
	local uri=$2
	shift 2
	local http_code=$($CURL \
		"$@" "$NEXUS_CONTENT_URL/$uri" \
		--output /dev/stderr --write-out "%{http_code}" \
		-v 2>"$LOCAL_DIR/.curl"\
		) || return 1
	case "$http_code" in
	2??)
		log "$actionCode $http_code $uri"
		return 0
		;;
	*)
		echo "$actionCode $http_code !$uri" >&2
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
		*'.md5'|*'.sha1') continue;;
		*'/maven-metadata.xml') continue;;
		esac
		#
		local uri=${filename:${#LOCAL_DIR}+1}
		case "$events" in
		'CLOSE_WRITE,CLOSE' | 'resync')
			nexusCurl "A" "$uri" --upload-file "$filename" || continue
			;;
		'DELETE' | 'DELETE,ISDIR')
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
        echo "ERROR: already running with pid=$pid"
        return 1
    fi
    # lock
    echo "$$" >"$pidfile"
}

#### MAIN

function doMain() {
# parse options

while [ -n "$1" ]; do
	local option="$1"
	shift
	case "$option" in
	'--dir')
		LOCAL_DIR="$1"
		shift
		;;
	'--user')
		NEXUS_USER_PASS=$1
		shift
		;;
	'--url')
		NEXUS_CONTENT_URL=$1
		shift
		;;
	'--'*)
		echo "ERROR: Unknown option: $option" >&2
		;;
	*) break;;
	esac
done

# DO NOT RUN TWICE on the same dir
checkSingletonLock || exit 1
#

LOGFILE="$LOCAL_DIR/.nexus-sync.log"
CURL="curl -u $NEXUS_USER_PASS"
case "$NEXUS_CONTENT_URL" in
'https://'*) CURL="$CURL -k";;
esac

resyncDirectory | syncToNexus
monitorDirectory | syncToNexus

}

doMain "$@"
