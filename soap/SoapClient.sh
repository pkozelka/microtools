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

##
# Performs low-level execution on the given endpoint.
# @param stdin - the request body
# @param operationName
# @file $TMP/${operationName}.request stored request
# @file $TMP/${operationName}.response stored response
# @file $TMP/${operationName}.response.code stored http code
# @returns curl's exitcode, or 99 to indicate non-ok HTTP code (2??)
#
function HttpCall() {
    local operationName="$1"
    cat >"$TMP/${operationName}.request"
#    echo $CURL "-d@$TMP/${operationName}.request" --output "$TMP/${operationName}.response" --write-out "%{http_code}" >"$TMP/${operationName}.response.code" >&2
    $CURL -d@"$TMP/${operationName}.request" --output "$TMP/${operationName}.response" --write-out "%{http_code}" >"$TMP/${operationName}.response.code"
    local rv="$?"
    case "$rv" in
    0);;
    *)
        echo "ERROR: curl failed - exitcode is $rv" >&2
        return $rv;;
    esac
    local http_code=$(cat "$TMP/${operationName}.response.code")
    case "$http_code" in
    2??);;
    *)
        echo "ERROR: server returned HTTP $http_code" >&2;
        return 99;;
    esac
}

function SoapCall() {
    local operationName="${1?'Please specify SOAP operation to call'}"
    shift
    #TODO: finetune processing of both request and response
    case "$operationName" in
    RAW)
        cat >"$TMP/${operationName}.request.prepared"
        ;;
    *)
        SOAP_OPERATION="$operationName"
        local soapRequestFunction="SOAP_${operationName}Request"
        if ! $soapRequestFunction "$@" >"$TMP/${operationName}.request.prepared"; then
            echo "ERROR: failed to execute '$soapRequestFunction'" >&2
            SOAP_OPERATION=""
            return 1
        fi
        SOAP_OPERATION=""
        ;;
    esac
    if "$DEBUG"; then
        # just show the request on console
        cat "$TMP/${operationName}.request.prepared"
        return 0
    fi

    # invoke service
    HttpCall "$operationName" < "$TMP/${operationName}.request.prepared" || return 1

    # process response status and data
    SoapClient_processResponse "$TMP/${operationName}.response" "$TMP/${operationName}.payload" || return 1


    local soapResponseFunction="SOAP_${operationName}Response"
    type -t "$soapResponseFunction" || soapResponseFunction="cat"
    eval $soapResponseFunction < "$TMP/${operationName}.payload"
}

function SoapClient_processResponse() {
    local responseFile="$1"
    local payloadFile="$2"

    xsltproc --output "$payloadFile" - "$responseFile" <<"EOF" || return 1
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                xmlns:env="http://schemas.xmlsoap.org/soap/envelope/" version="1.0">
    <xsl:output method="xml" indent="yes"/>
    <xsl:template match="env:Envelope">
        <xsl:apply-templates select="env:*"/>
    </xsl:template>
    <xsl:template match="env:Body">
        <xsl:apply-templates select="env:Fault"/>
        <xsl:apply-templates select="*" mode="iden"/>
    </xsl:template>
    <xsl:template match="env:Fault">
        <xsl:message terminate="yes">
            <xsl:text>SOAP Fault: faultcode="</xsl:text>
            <xsl:value-of select="faultcode"/>
            <xsl:text>", message="</xsl:text>
            <xsl:value-of select="faultstring"/>
            <xsl:text>", detail="</xsl:text>
            <xsl:value-of select="detail"/>
            <xsl:text>"</xsl:text>
        </xsl:message>
    </xsl:template>

    <!-- identity transform -->
    <xsl:template match="@*|text()|comment()|processing-instruction()" mode="iden">
        <xsl:copy-of select="."/>
    </xsl:template>
    <xsl:template match="*" mode="iden">
        <xsl:copy>
            <xsl:apply-templates select="@*" mode="iden"/>
            <xsl:apply-templates select="*|processing-instruction()|comment()|text()" mode="iden"/>
        </xsl:copy>
    </xsl:template>
</xsl:stylesheet>
EOF
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
    local requestElement
    if [ "$1" == "--element" ]; then
        requestElement="${2}"
        shift 2
    elif [ -n "$SOAP_OPERATION" ]; then
        requestElement="${SOAP_OPERATION}Request"
    else
        echo "ERROR: No SOAP operation in progress" >&2
        return 1
    fi

    #TODO: allow headers to come via options?
    cat <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<Envelope xmlns="http://schemas.xmlsoap.org/soap/envelope/">
  <Header/>
  <Body>
EOF
    if read; then
        echo "    <$requestElement xmlns=\"$ENDPOINT_NAMESPACE\">"
        # pass the body through
        echo "$REPLY"
        cat
        #
        echo "    </$requestElement>"
    else
        echo "    <$requestElement xmlns=\"$ENDPOINT_NAMESPACE\"/>"
    fi
    cat <<EOF
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
    LOCAL_DIR="${PWD}"
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
        '--dir')
            # synchronization source directory
            LOCAL_DIR="$1"
            shift
            ;;
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
        ${CURL}${ENDPOINT_WSDL} | xmllint --format - || exit 1
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
        $CURL -d@-
    elif grep -q "^function CMD_$command()" "$0"; then
        # execute the recognized subcommand by calling its function
        CMD_$command "$@"
    else
        echo "ERROR: Invalid command: '$command'; use $0 --help to see available commands" >&2
        return 1
    fi
}
