#!/bin/bash

MV="git mv"

function rename() {
    local file=$1
    local className=$2
}

##
# Filters control file into pairs of NEW,OLD package per line
#
function readControlFile() {
    sed '/^#/d;/^$/d;s:=: :' $CONTROLFILE
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

function refactorAllClasses() {
    # prepare sed scripts
    readControlFile | while read newClass oldClass; do
        printf "s:${oldClass//./\.}:${newClass}:g;\n" >>$TMP/java-fix-imports.sed
    done
    # process all java files
    find * -name '*.java' | while read file; do
        javaFixImports "$file" || return 1
    done
    # TODO
}

function doFileRenames() {
    # translate control file into SED
    #   which generates "mv" arg pairs, one per line, for piped `find`

    # first, just individual class renames
    local new old
    readControlFile | while read new old; do
        local newClass="${new/#*\./}"
        [ -z "$newClass" ] && continue
        local newPackage="${new%.*}"
        local oldClass="${old/#*\./}"
        local oldPackage="${old%.*}"
        case "$oldClass" in
        '') oldClass="$newClass"; old="$old$newClass";;
        esac
#        printf "$oldPackage:$oldClass --> $newPackage:$newClass"
        local oldPath="${oldPackage//\.//}"
        local newPath="${newPackage//\.//}"
#        printf "$oldPath/$oldClass --> $newPath/$newClass :SED: "
        # SED: filenames on input - find * -name '*.java'
        #      dir + args for mv on output
        printf '/\/%s\.java$/{s:^\(.*\)/%s\.java$:\\1 %s.java %s:;p;}\n' "${oldPath//\//\\/}\/$oldClass" "$oldPath/$oldClass" "$oldPath/$oldClass" "$newPath/$newClass"
    done
}

#### MAIN ####

CONTROLFILE=${1-'rename.txt'}

TMP=/tmp/refactor
rm -rf $TMP
mkdir -p $TMP

doFileRenames "$CONTROLFILE"
