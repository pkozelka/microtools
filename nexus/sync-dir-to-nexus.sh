#!/bin/bash

# Defaults for parameters
NEXUS_USER_PASS="admin:admin123"
NEXUS_CONTENT_URL="http://localhost:8081/service/local/repositories/releases/content"
LOCAL_DIR="$PWD"
#

function log() {
	echo "$@"
	echo "$@" >>$LOGFILE
}

function monitorDirectory() {
	inotifywait -q -m -r \
		-e close_write,delete \
		--format '%e %w%f' \
		@$LOGFILE \
		"$LOCAL_DIR"
}

function syncToNexus() {
	local CURL="curl -u $NEXUS_USER_PASS"
	case "$NEXUS_CONTENT_URL" in
	'https://'*) CURL="$CURL -k";;
	esac
	local events filename
	while read events filename; do
		# inotify exclusion doesn't seem to work
		[ "$filename" == "$LOGFILE" ] && continue
		#
		local uri=${filename:${#LOCAL_DIR}+1}
		case "$events" in
		'CLOSE_WRITE,CLOSE')
			log "a $filename"
			$CURL --upload-file "$filename" "$NEXUS_CONTENT_URL/$uri" || continue
			log "A $filename"
			;;
		'DELETE' | 'DELETE,ISDIR')
			log "d $filename"
			$CURL -X DELETE "$NEXUS_CONTENT_URL/$uri" || continue
			log "D $filename"
			;;
		esac
	done
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

LOGFILE="$LOCAL_DIR/.nexus-sync.log"

#TODO: sync all files omitted in the meantime: findFilesOlderThanLog | syncToNexus

monitorDirectory | syncToNexus

}

doMain "$@"
