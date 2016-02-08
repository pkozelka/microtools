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

function smartRename() {
    local verbose=""
    if [ "$1" == '--verbose' ]; then
        verbose="-v"
        shift
    fi
    local sourceRoot="$1"
    local origFile="$2"
    local newFile="$3"
    [ -f "$sourceRoot/$origFile" ] || return
    mkdir -p "$sourceRoot/${newFile%/*}"
    $MV $verbose "$sourceRoot/$origFile" "$sourceRoot/$newFile" || return 1
    # refactor
    case "$origFile" in
    *'.java'|*'.groovy') 
        local newPackage=${newFile%/*.*}
        newPackage=${newPackage//\//.}
        sed -i 's:^package .*$:package '"${newPackage}"';:' "$sourceRoot/$newFile" || return 1
        ;;
    esac;
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
            echo "RENAMING $sourceRoot/$oldPath --> $sourceRoot/$newPath" >&2
            local oldJavaFile
            find "$sourceRoot/$oldPath" -type f | while read oldFileFull; do
                local oldFile=${oldFileFull:${#sourceRoot}+1}
                local regex=${oldPath//\//\\/}
                local newFile=${oldFile//$regex/$newPath}
                if [ "$newFile" == "$oldFile" ]; then
                    echo "ERROR: Unchanged ? $regex ? $newFile" >&2
                    continue
                fi
                smartRename "$sourceRoot" "$oldFile" "$newFile"
            done
        else
            # individual file rename
            case "$oldClass" in
            '') oldClass="$newClass"; old="$old$newClass";;
            esac
            smartRename --verbose "$sourceRoot" "$oldPath/$oldClass.java" "$newPath/$newClass.java"
        fi
    done
}

function listModuleRoots() {
    local basedir
    find * -name 'pom.xml' -printf '%h\n' | sort | while read basedir; do
        for i in src/main/java src/test/java src/main/resources src/test/resources src/main/webapp/WEB-INF/classes src/main/resources/moxy; do
            [ -d "$basedir/$i" ] && echo "$basedir/$i"
        done
    done
}

function renameJavaFiles() {
    local sourceRoot
    for sourceRoot in `listModuleRoots`; do
        doFileRenames "$sourceRoot"
    done
}

function fixReferences() {
    echo "Gathering reference changes"
    local new old
    readControlFile | while read new old; do
        local regex="${old//./\\.}"
        printf '/^import \\(static \\)\\?%s/{s:%s:%s:}\n' "$regex" "$regex" "$new" >>"$TMP/fixReferences.sed"
        printf 's:%s:%s:g;\n' "$regex" "$new" >>"$TMP/fixReferences.sed"
        local oldSlash="${old//.//}"
        local newSlash="${new//.//}"
        printf 's:%s:%s:g;\n' "$oldSlash" "$newSlash" >>"$TMP/fixReferences.sed"
    done
    local sourceRoot
    for sourceRoot in `listModuleRoots`; do
        echo "Fixing references in $sourceRoot"
        find $sourceRoot -type f | xargs sed -i -f "$TMP/fixReferences.sed"
    done
    echo "Fixing references in pom.xml files"
    sed -i -f "$TMP/fixReferences.sed" $(find * -name "pom.xml")
}

#### MAIN ####

CONTROLFILE='rename.txt'

TMP=/tmp/refactor

rm -rf $TMP
mkdir -p $TMP

renameJavaFiles
fixReferences
