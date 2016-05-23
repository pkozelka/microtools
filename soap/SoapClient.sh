#!/bin/bash
#
# Commandline client for SOAP Web Services
# (C) 2016 Petr Kozelka <pkozelka@gmail.com>
#
# Embedding into wrappers scripts:
#   [ -s SoapClient.sh ] || wget --progress=dot:mega -N "https://raw.githubusercontent.com/pkozelka/microtools/master/soap/SoapClient.sh" || exit 1
#   chmod +x "SoapClient.sh" && source "./SoapClient.sh"
#   SoapClient "$@"
#
[ -s "SoapClient.config" ] && source "SoapClient.config"

function SoapCall() {
    local operationName="${1?'Please specify SOAP operation to call'}"
    shift
    #TODO: finetune processing of both request and response
    SOAP_OPERATION="$operationName"
    local soapRequestFunction="SOAP_${operationName}Request"
    local soapResponseFunction="SOAP_${operationName}Response"
    if "$DEBUG"; then
        # just show the request on console
        $soapRequestFunction "$@"
    else
        if ! $soapRequestFunction "$@" >$TMP/${operationName}.request; then
            echo "ERROR: failed to execute '$soapRequestFunction'" >&2
            return 1
        fi
        $CURL "-d@$TMP/${operationName}.request" >"$TMP/${operationName}.response"

        type -t "$soapResponseFunction" || soapResponseFunction="cat"
        $soapResponseFunction < "$TMP/${operationName}.response"
    fi
    local rv="$?"
    SOAP_OPERATION=""
    return "$rv"
}

function SoapClient_help() {
    cat <<EOF
Commandline client for SOAP Web Services
(C) 2016, Petr Kozelka

Usage:
    $0 [<options>] <subcommand>

Options:
    --config
            reads configuration file
    --url <url>
            sets URL base for the endpoint
    --user <name>:<password>
            sets basic authentication for the web service call
    --wsdl  just show wsdl and exit
    -       absorb stdin as is and pass it to the endpoint

Subcommands (generated from CMD_* functions in main script):
EOF
    sed -n '/^function CMD_/{s:^.*CMD_:    :;s:().*$::;p;}' "$0"
}

##
# Standard wrapping for request body - soap envelope
#
function SoapEnvelope() {
    #TODO: allow headers to come via options?
    cat <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<Envelope xmlns="http://schemas.xmlsoap.org/soap/envelope/">
  <Header/>
  <Body>
EOF
    # pass the body through
    cat
    #
    cat <<EOF
  </Body>
</Envelope>
EOF
}

##
# Wraps the payload with a SOAP request.
#
function SoapRequest() {
    local requestElement="${SOAP_OPERATION?'No soap operation in progress!'}Request"
    if [ "$1" == "--element" ]; then
        requestElement="${2}"
        shift 2
    fi
    #TODO: allow headers to come via options?
    cat <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<Envelope xmlns="http://schemas.xmlsoap.org/soap/envelope/">
  <Header/>
  <Body>
    <$requestElement xmlns="$ENDPOINT_NAMESPACE">
EOF
    # pass the body through
    cat
    #
    cat <<EOF
    </$requestElement>
  </Body>
</Envelope>
EOF
}

##
# Unwraps payload from the SOAP response
#
function SoapResponse() {
    cat ## TODO
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
        '--debug')
            DEBUG="true"
            echo "!!! DEBUG MODE !!!" >&2
            ;;
        '--tmp')
            TMP="$1"
            shift
            ;;
        '--help')
            # print usage information
            SoapClient_help "$@"
            return 0;;
        *) echo "ERROR: Invalid option: $option" >&2
            return 1;;
        esac
    done

    if [ -z "$REMOTE_URL" ]; then
        echo "ERROR: Missing REMOTE_URL - use either config property 'REMOTE_URL' or argument '--url'"
        return 1
    fi

    CURL="curl -s -k ${CURL_AUTH} ${REMOTE_URL}${ENDPOINT_URI}"
    if $showWsdl; then
        ${CURL_GET}${ENDPOINT_WSDL} | xmllint --format - || exit 1
        return 0
    fi
    CURL="$CURL --header Content-Type:text/xml;charset=UTF-8 -X POST"

    [ "$DEBUG" == "true" ] || DEBUG="false"

    local command="${1?'Please specify a subcommand; use --help option to list available subcommands'}"
    shift

    [ -z "$TMP" ] && TMP="/tmp/SoapClient/${0/#*\/}"
    mkdir -p "$TMP"

    if [ "$command" == "-" ]; then
        # absorb stdin and pass it to the endpoint
        $DEBUG && echo "$CURL -d@-" >&2
        $CURL_POST -d@-
    elif grep -q "^function CMD_$command()" "$0"; then
        # execute the recognized subcommand by calling its function
        CMD_$command "$@"
    else
        echo "ERROR: Invalid command: '$command'; use $0 --help to see available commands" >&2
        return 1
    fi
}
