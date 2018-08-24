#!/bin/bash

## Set given directory as the new (and only!) java home in both JAVA_HOME and PATH.
## This script needs to be sourced.

JH="${1?'please specify desired JAVA_HOME'}"
JHB="$JH/bin"

export JAVA_HOME="$JH"

# remove any paths that contain java or do not exist
__NEW_PATH="$JHB"
for i in ${PATH//:/ }; do
	if ! [ -d "$i" ]; then
		echo "!! $i" >&2
	elif [ -x "$i/java" ]; then
		echo "-- $i" >&2
	else
#		echo "   $i" >&2
		__NEW_PATH="$__NEW_PATH:$i"
	fi
done
echo "++ $JHB" >&2


export PATH="$__NEW_PATH"
unset __NEW_PATH
java -version
