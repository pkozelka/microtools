#!/bin/bash

MV="git mv"

function rename() {
    local file=$1
    local className=$2
}

function javaFixImports() {
    local javaFile=$1
    # rename
    # fix package
    # fix class name
    # fix FQ references
    sed -i -f "$TMP/java-fix-imports.sed" "$javaFile" || return 1
    # fix class references if package is imported
}

function renameAllClasses() {
    local controlFile='rename.txt'
    # prepare sed scripts
    sed 's:=: :' "$controlFile" | while read newClass oldClass; do
        printf "s:${oldClass//./\.}:${newClass}:g;\n" >>$TMP/java-fix-imports.sed
    done
    # process all java files
    find * -name '*.java' | while read file; do
        javaFixImports "$file" || return 1
    done
}

#### MAIN ####

TMP=/tmp/refactor
rm -rf $TMP
mkdir -p $TMP

renameAllClasses
