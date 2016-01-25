#!/bin/bash

MV="mv"

function rename() {
    local file=$1
    local className=$2
}

function processJavaFile() {
    local javaFile=$1
    # rename
    # fix package
    # fix class name
    # fix FQ references
    sed -f "$TMP/fix-fq-refs.sed" "$javaFile" || return 1
    # fix class references if package is imported
}

function renameAllClasses() {
    local controlFile='rename.txt'
    # prepare sed scripts
    sed 's:=: :' "$controlFile" | while read newClass oldClass; do
        printf "s:${oldClass//./\.}:${newClass}:g;\n" >>$TMP/fix-fq-refs.sed
    done
    # process all java files
    find * -name '*.java' | while read file; do
        processJavaFile "$file" || return 1
    done
}

#### MAIN ####

TMP=/tmp/refactor
rm -rf $TMP
mkdir -p $TMP

renameAllClasses
