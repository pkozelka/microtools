#!/bin/bash
#
# TAB throttler (C) Petr Kozelka
# http://github.com/pkozelka/microtools/tabs/
#

TYPES="xml,java,sql"

function countTabs() {
    local file=$1
    tr -dc '\t' <$file | wc -c
}

function listTabCountsInDir() {
    find * -type f | while read; do
        local file="$REPLY"
        local ext=${file/#*.}
        case ",$TYPES," in
        *,$ext,*);;
        *) continue;;
        esac
        cnt=$(countTabs "$file")
        [ "$cnt" == "0" ] && continue
        printf "%8d %s\n" "$cnt" "$file"
    done
}

function error() {
    local file="$1"
    local msg="$2"
    echo "ERROR:   $file : $msg" | tee -a "$TMP/errors.txt"
}

function warning() {
    local file="$1"
    local msg="$2"
    echo "WARNING: $file : $msg" | tee -a "$TMP/warnings.txt"
}

function check() {
    local toleratedFile="$1"
    listTabCountsInDir | tee "$TMP/proposal.txt" | while read cnt file; do
        # do we know this file?
        local expr="${file//\//\\/}"
        expr=${expr//\./\\.}
        local toleratedCount=$(sed -n '/ '"$expr"'$/{s#^[[:space:]]*##;s: .*$::;p;}' "$toleratedFile")
#        echo "cOMPARING: '$toleratedCount' AND '$cnt' EXPR: '$expr'"
        if [ -z "$toleratedCount" ]; then
            error "$file" "Introduces $cnt TAB characters"
        else
            toleratedCount=$(( toleratedCount ))
            cnt=$(( cnt ))
#            echo "COMPARING: '$toleratedCount' AND '$cnt'"
            if [ "$toleratedCount" -lt "$cnt" ]; then
                # there are some new tabs
                error "$file" "Exceeds tolerated count (actual: $cnt, tolerated: $toleratedCount)"
            elif [ "$toleratedCount" -eq "$cnt" ]; then
                continue
            else
                warning "$file" "Toleration should be reduced: $toleratedCount -> $cnt"
            fi
        fi
    done
    if [ -s "$TMP/proposal.txt" ]; then
        printf "%5d files contain TABs\n" $(cat "$TMP/proposal.txt" | wc -l)
    fi

    if [ -s "$TMP/errors.txt" ]; then
        printf "%5d files exceed tolerated TAB counts\n" $(cat "$TMP/errors.txt" | wc -l)
        return 1
    fi

    if [ -s "$TMP/warnings.txt" ]; then
        echo "Please reduce your toleration to TABs by replacing your tolerance file with following content:"
        echo '-----'
        sort -k1 -n -r "$TMP/proposal.txt"
        echo '-----'
    fi
    true
}

function printUsage() {
    cat <<EOF
Usage:
    $0 <command> [options]

Command "list"
    - finds all matching files with TABs and prints them out

Command "check"
    - finds all matching files with TABs and compares them with existing "tolerated" listing
    - fails if number of TABs increased in any single fail
    - if number of TABs decreased in one or more files, prints the new suggested "tolerated" listing to make it tighter
EOF
}

#### MAIN ####

TMP="$PWD/.git/tmp-tabs"
CMD="$1"
shift

rm -rf "$TMP" && mkdir "$TMP" || exit 1
rm -rf "$TMP/*"

case "$CMD" in
'list')
    listTabCountsInDir | sort -k1 -n
    ;;
'check')
    check ${1?'Specify your tab-tolerance file'}
    ;;
'')
    echo "ERROR: A command expected." >&2
    printUsage
    exit 1
    ;;
*) echo "ERROR: Unknown command '$CMD'." >&2
esac
