#!/bin/bash

# Replaces space in file names with underscore

for i in "$@"; do
	x="${i// /_}"
	[ "$i" == "$x" ] || mv -v "$i" "$x"
done
