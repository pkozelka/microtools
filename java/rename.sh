#!/bin/bash

MV="git mv"
ADD="git add"

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
    local sourceRoot="$1"
    local origFile="$2"
    local newFile="$3"
    [ -f "$sourceRoot/$origFile" ] || return
    local newPackage=${newFile%/*.*}
    newPackage=${newPackage//\//.}
    mkdir -p "$sourceRoot/${newFile%/*}"
    $MV $verbose "$sourceRoot/$origFile" "$sourceRoot/$newFile" || return 1
    sed -i 's:^package .*$:package '"${newPackage}"';:' "$sourceRoot/$newFile" || return 1
    $ADD "$sourceRoot/$newFile" || return 1
    rmdir --parents --ignore-fail-on-non-empty "$sourceRoot/${origFile%/*}"
}

function doFileRenames() {
    local sourceRoot="$1"
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
            find "$sourceRoot/$oldPath" -name '*.java' | while read oldJavaFileFull; do
                local oldJavaFile=${oldJavaFileFull:${#sourceRoot}+1}
                local regex=${oldPath//\//\\/}
                local newJavaFile=${oldJavaFile//$regex/$newPath}
                if [ "$newJavaFile" == "$oldJavaFile" ]; then
                    echo "ERROR: Unchanged ? $regex ? $newJavaFile" >&2
                    continue
                fi
                javaRename "$sourceRoot" "$oldJavaFile" "$newJavaFile"
            done
        else
            # single file rename
            case "$oldClass" in
            '') oldClass="$newClass"; old="$old$newClass";;
            esac
            javaRename --verbose "$sourceRoot" "$oldPath/$oldClass.java" "$newPath/$newClass.java"
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

function renameJavaFiles() {
    for sourceRoot in `listModuleRoots`; do
        doFileRenames "$sourceRoot"
    done
}

function fixJavaImports() {
    true # TODO
}

#### MAIN ####

CONTROLFILE='rename.txt'

TMP=/tmp/refactor

rm -rf $TMP
mkdir -p $TMP

renameJavaFiles
