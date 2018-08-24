#!/bin/bash

JH="${1?'please specify desired JAVA_HOME'}"
JHB="$JH/bin"

export JAVA_HOME="$JH"

# TODO: remove any paths that contain java or do not exist
__NEW_PATH="$JHB"
for i in ${PATH//:/ }; do
	if [ -x "$i/java" ]; then
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
