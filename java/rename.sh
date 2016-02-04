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

function mvJavaFile() {
    echo "$@"
}

function mvJavaTree() {
    echo "$@"
}

function doFileRenames() {
    # translate control file into SED
    #   which generates "mv" arg pairs, one per line, for piped `find`
    cat <<EOF >"$TMP/name-filter.sh"
while read REPLY; do
case "\$REPLY" in
EOF
    cat <<EOF >"$TMP/name-filter.sh.2"
*) continue;;
esac
done
EOF
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
            echo "$oldPath $newPath" >>$TMP/mv-package.txt
            echo '*/'"$oldPath"') '"$0"' mvJavaTree "$REPLY" "$oldPackage" "$newPackage";;' >>"$TMP/name-filter.sh"
            echo '*/'"$oldPath"'/*) '"$0"' mvJavaTree "$REPLY" "$oldPackage" "$newPackage";;' >>"$TMP/name-filter.sh"
        else
            # schedule single file rename
            case "$oldClass" in
            '') oldClass="$newClass"; old="$old$newClass";;
            esac
#            printf "$oldPackage:$oldClass --> $newPackage:$newClass"
#            printf "$oldPath/$oldClass --> $newPath/$newClass :SED: "
            # SED: filenames on input - find * -name '*.java'
            #      dir + args for mv on output
            printf '/\/%s\.java$/{s:^\(.*\)/%s\.java$:'"$0"' mvJavaFile \\1 %s.java %s:;p;}\n' "${oldPath//\//\\/}\/$oldClass" "$oldPath/$oldClass" "$oldPath/$oldClass" "$newPath/$newClass" >>$TMP/mv-file.sed
        fi
    done
    cat "$TMP/name-filter.sh.2" >>"$TMP/name-filter.sh"
    find * -name '*.java' >$TMP/files.txt
    find * -type f >$TMP/dirs.txt
    sed -n -f $TMP/mv-file.sed $TMP/files.txt >$TMP/rename1.sh
    sh $TMP/rename1.sh
    sort -u "$TMP/dirs.txt" | sh "$TMP/name-filter.sh"
}

function listModuleRoots() {
    local basedir
    find $PWD/* -name 'pom.xml' -printf '%h\n' | sort | while read basedir; do
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
#    doFileRenames
    listModuleRoots
    ;;
*) "$@";;
esac

