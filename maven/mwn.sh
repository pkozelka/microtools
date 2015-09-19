#!/bin/bash
#
# MyMaven - wrapper script for Maven which adds some features to the build
#
# First of all, it finds nearest enclosing `.mw` directory; if found, uses its `settings.xml`, `repository`, and other files.
#
# `mw` stands for Maven Workspace here.
#

# https://github.com/builddoctor/maven-antsy-color

# thanks to:  http://blog.blindgaenger.net/colorize_maven_output.html
# and: http://johannes.jakeapp.com/blog/category/fun-with-linux/200901/maven-colorized
# and: Martin Frýdl
# + some improvements of my own - Petr Kozelka
# Colorize Maven Output
function colorize() {
    local esc=""
    local BLUE="$esc[0;34m"
    local RED="$esc[0;31m"
    local LIGHT_RED="$esc[1;31m"
    local LIGHT_GRAY="$esc[0;37m"
    local LIGHT_GREEN="$esc[1;32m"
    local LIGHT_BLUE="$esc[1;34m"
    local LIGHT_CYAN="$esc[1;36m"
    local YELLOW="$esc[1;33m"
    local WHITE="$esc[1;37m"
    local NO_COLOUR="$esc[0m"
    "$@" | sed \
-e "s/\(.*-\{55\}\+$\|.*\[INFO\] Scanning for projects.*\|.*\[INFO\] Building.*\|^Running .*\|^ T E S T S$\|^Results.*\)/${WHITE}\1${NO_COLOUR}/g" \
-e "s/\(.*\[INFO\] BUILD SUCCESS$\|^Tests run:.*Failures: 0.*Errors: 0.*Skipped: 0.*\)/${LIGHT_GREEN}\1${NO_COLOUR}/g" \
-e "s/\(.*\[WARNING].*\|^NOTE: Maven is executing in offline mode\.\|^Tests run:.*Failures: 0, Errors: 0, Skipped: [^0].*\)/${YELLOW}\1${NO_COLOUR}/g" \
-e "s/\(.*\[INFO\] BUILD FAILURE\|.* <<< FAILURE!$\|.* <<< ERROR!$\|^Tests in error:.*\|^Tests run:.*Failures: [^0].*\|^Tests run:.*Errors: [^0].*\|.*\[ERROR\].*\)/${LIGHT_RED}\1${NO_COLOUR}/g" \
-e "s/\(^\[INFO\] --- \)\(.*\)\( @ .* ---\)/\1${LIGHT_BLUE}\2${NO_COLOUR}\3/g" \
-e "s/\(^\[INFO\] \)\(>>> \)\(.*\)\( > .* @ .*\)/\1${LIGHT_CYAN}\2${LIGHT_BLUE}\3${LIGHT_CYAN}\4${NO_COLOUR}/g" \
-e "/^\[INFO\] .\{52\} /s/\( SUCCESS \)/${LIGHT_GREEN}\1${NO_COLOUR}/g" \
-e "/^\[INFO\] .\{52\} /s/\( FAILURE \)/${LIGHT_RED}\1${NO_COLOUR}/g" \
-e "/^\[INFO\] .\{52\} /s/\( SKIPPED\)/${YELLOW}\1${NO_COLOUR}/g"
    return $PIPESTATUS
}

##
# Find enclosing workspace
# @param dir  where the search will start.
# @stdout the found location; $HOME/.m2 if no other found
function findWorkspace() {
    local dir=$1
    local default=$HOME/.m2
    local mw
    while true; do
        case "$dir" in
        ''|$HOME) mw="$default"; break;;
        esac
        if [ -d "$dir/.mw" ]; then
            mw="$dir/.mw"
            break
        fi
        dir="${dir%/*}"
    done
    echo "$mw"
    test -r "$mw/mwn.env"
}

function getMvnCommandline() {
    if [ -n "$M2_HOME" ]; then
        printf "$M2_HOME/bin/"
    fi
    printf "mvn"
    # for default workspace, we don't enhance commandline
    case "$MW" in
    "$HOME/.m2") return;;
    esac

    if [ -r "$MW/settings.xml" ]; then
        printf " --settings %s" $(readlink -f "$MW/settings.xml")
    fi

    if [ -r "$MW/repository" ]; then
        printf " -Dmaven.repo.local=%s" $(readlink -f "$MW/repository")
    fi
}

function runMaven() {
    echo "$@"
    local timestamp=$(date -Isec)
    echo "#$timestamp# cd $PWD && $@" >> "$MW/.mwn_history"
    colorize "$@"
}

MW=$(findWorkspace $PWD)
if [ -r "$MW/mwn.env" ]; then
    source "$MW/mwn.env" || return 1
    if ! [ -x "$M2_HOME/bin/mvn" ]; then
        echo "ERROR: mwn.env must specify M2_HOME pointing to a real maven distribution" >&2
        exit 1
    fi
elif [ "$1" == "--env" ]; then
    mvn=$(which mvn)
    mvn=$(readlink -f "$mvn")
    javac=$(which javac)
    echo "Creating file $MW/mwn.env"
    cat <<EOF | tee $MW/mwn.env
M2_HOME=${mvn%/bin/mvn}
JAVA_HOME=${javac%/bin/javac}
EOF
    exit 0
else
    echo "ERROR: Missing environment file: $MW/mwn.env; use '--env' to create one" >&2
    exit 1
fi
echo "MW=$MW"
runMaven $(getMvnCommandline) "$@"
