#!/bin/bash
#
# Commandline client for SOAP Web Services
# Petr Kozelka (C) 2016
#

[ -s "SoapClient.config" ] && source "SoapClient.config"

function SoapClient_help() {
    cat <<EOF
Commandline client for SOAP Web Services
(C) 2016, Petr Kozelka

Usage:
    $0 [<options>] command

Options:
    --config
            reads configuration file
    --url <url>
            sets URL base for the endpoint
    --user <name>:<password>
            sets basic authentication for the web service call
    --wsdl  just show wsdl and exit
    -       absorb stdin as is and pass it to the endpoint

Commands (generated from CMD_* functions in main script):
EOF
    sed -n '/^function CMD_/{s:^.*CMD_:    :;s:().*$::;p;}' "$0"
}

function SoapCall() {
    local operationName="$1"
    shift
    #TODO: finetune processing of both request and response
    SOAP_${operationName}Request "$@" | $CURL_POST -d@-
}

function SoapClient() {
    local showWsdl="false"
    while [ "${1:0:2}" == "--" ]; do
        option="$1"
        shift
        case "$option" in
        '--config')
            # use specific configuration
            source "$1" || return 1
            shift;;
        '--url')
            # set url base
            REMOTE_URL="$1"
            shift;;
        '--user')
            # set authentication, in form user:password
            CURL_AUTH="-u $1"
            shift;;
        '--wsdl')
            # show WSDL and exit
            showWsdl="true"
            shift;;
        '--help')
            # print usage information
            SoapClient_help "$@"
            return 0;;
        *) echo "ERROR: Invalid option: $option" >&2
            return 1;;
        esac
    done

    CURL_GET="curl -s -k ${CURL_AUTH} ${REMOTE_URL}${ENDPOINT_URI}"
    CURL_POST="curl -s -k --header Content-Type:text/xml;charset=UTF-8 -X POST ${CURL_AUTH} ${REMOTE_URL}${ENDPOINT_URI}"

    if $showWsdl; then
        ${CURL_GET}${ENDPOINT_WSDL} | xmllint --format - || exit 1
        return 0
    fi

    local command="$1"
    shift

    if [ "$command" == "-" ]; then
        # absorb stdin and pass it to the endpoint
        $CURL_POST -d@-
    elif grep -q '^function CMD_'$command'()' "$0"; then
        # execute the recognized subcommand by calling its function
        CMD_$command "$@"
    else
        echo "ERROR: Invalid command: '$command'; use $0 --help to see available commands" >&2
    fi
}