#!/bin/bash
#
# Commandline client for SOAP Web Services
# Petr Kozelka (C) 2016
#

[ -s "SoapClient.config" ] && source "SoapClient.config"

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
}
