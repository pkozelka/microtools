#!/bin/bash

# Defaults for parameters
NEXUS_USER_PASS="admin:admin123"
NEXUS_CONTENT_URL="http://localhost:8081/service/local/repositories/releases/content"
LOCAL_DIR="$PWD"
#

function monitorDirectory() {
	inotifywait -q -m -e close_write,delete --format '%e %w%f' -r "$LOCAL_DIR"
}

function syncToNexus() {
	local CURL="curl -u $NEXUS_USER_PASS"
	case "$NEXUS_CONTENT_URL" in
	'https://'*) CURL="$CURL -k";;
	esac
	local events filename
	while read events filename; do
		local uri=${filename:${#LOCAL_DIR}+1}
		case "$events" in
		'CLOSE_WRITE,CLOSE')
			$CURL --upload-file "$filename" "$NEXUS_CONTENT_URL/$uri"
			;;
		'DELETE' | 'DELETE,ISDIR')
			$CURL -X DELETE "$NEXUS_CONTENT_URL/$uri"
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

#TODO: log all synced changes

#TODO: sync all files omitted in the meantime: findFilesOlderThanLog | syncToNexus

monitorDirectory | syncToNexus

}

doMain "$@"
