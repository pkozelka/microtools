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

function javaRename() {
    local verbose=""
    if [ "$1" == '--verbose' ]; then
        verbose="-v"
        shift
    fi
    local origFile="$1"
    local newFile="$2"
    [ -f "$origFile" ] || return
    mkdir -p "${newFile%/*}"
    $MV $verbose "$origFile" "$newFile" || return 1
    rmdir --parents --ignore-fail-on-non-empty "${origFile%/*}"
}

function doFileRenames() {
    local sourceRoot="$1"
    # first, just individual class renames
    local new old
    readControlFile | while read new old; do
        local newClass="${new/#*\./}"
        local newPackage="${new%.*}"
        local oldClass="${old/#*\./}"
        local oldPackage="${old%.*}"
        local oldPath="${oldPackage//\.//}"
        local newPath="${newPackage//\.//}"
        if [ -z "$newClass" ]; then
            # just change package
            if [ -n "$oldClass" ]; then
                echo "ERROR: Nonsense in input: '$new=$old'" >&2
                exit 1
            fi
            # recursively rename all java files
            [ -d "$sourceRoot/$oldPath" ] || continue
            local oldJavaFile
            find "$sourceRoot/$oldPath" -name '*.java' | while read oldJavaFile; do
                local regex=${oldPath//\//\\/}
                local newJavaFile=${oldJavaFile//$regex/$newPath}
                if [ "$newJavaFile" == "$oldJavaFile" ]; then
                    echo "ERROR: Unchanged ? $regex ? $newJavaFile" >&2
                    continue
                fi
                javaRename "$oldJavaFile" "$newJavaFile"
            done
        else
            # single file rename
            case "$oldClass" in
            '') oldClass="$newClass"; old="$old$newClass";;
            esac
            javaRename --verbose "$sourceRoot/$oldPath/$oldClass.java" "$sourceRoot/$newPath/$newClass.java"
        fi
    done
}

function listModuleRoots() {
    local basedir
    find * -name 'pom.xml' -printf '%h\n' | sort | while read basedir; do
        for i in src/main/java src/test/java src/main/resources src/test/resources src/main/webapp/WEB-INF/classes; do
            [ -d "$basedir/$i" ] && echo "$basedir/$i"
        done
    done
}

#### MAIN ####

CONTROLFILE='rename.txt'

TMP=/tmp/refactor

case "$1" in
'')
    rm -rf $TMP
    mkdir -p $TMP
    for sourceRoot in `listModuleRoots`; do 
        doFileRenames "$sourceRoot"
    done
    ;;
*) "$@";;
esac

