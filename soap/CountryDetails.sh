#!/bin/bash

REMOTE_URL="http://www.webservicex.net"
ENDPOINT_URI="/country.asmx"
ENDPOINT_WSDL="?WSDL"
ENDPOINT_NAMESPACE="http://www.webserviceX.NET"

##
# Shows all countries.
#
# This implementation demonstrates usage of function "SoapEnvelope" which conveniently
# wraps the message with SOAP Envelope/Body stuff.
#
# Here we feed the data to SoapEnvelope via function argument.
#
function SOAP_GetCountriesRequest() {
    SoapEnvelope "<GetCountries xmlns='$ENDPOINT_NAMESPACE' />"
}

##
# Shows one country selected by country code
#
# This implementation demonstrates usage of function "SoapEnvelope" which conveniently
# wraps the message with SOAP Envelope/Body stuff.
#
# Here we feed the data to SoapEnvelope via pipe.
#
function SOAP_GetCountryByCountryCodeRequest() {
    local countryCode="$1"
    SoapEnvelope <<EOF
    <GetCountryByCountryCode xmlns="$ENDPOINT_NAMESPACE">
      <CountryCode>${countryCode}</CountryCode>
    </GetCountryByCountryCode>
EOF
}

##
# Show ISD for given country.
# Sample usage:
#   ./CountryDetails.sh isd italy
#
# This implementation demonstrates complete control over transmitted SOAP message.
#
function SOAP_GetISDRequest() {
    local countryName="$1"
    cat <<EOF
<?xml version="1.0" encoding="utf-8"?>
<soap:Envelope xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/">
  <soap:Body>
    <GetISD xmlns="$ENDPOINT_NAMESPACE">
      <CountryName>${countryName}</CountryName>
    </GetISD>
  </soap:Body>
</soap:Envelope>
EOF
}

function CMD_countries() {
    SoapCall GetCountries "$@"
}

function CMD_country() {
    SoapCall GetCountryByCountryCode "$@"
}

function CMD_isd() {
    SoapCall GetISD "$@"
}

[ -s SoapClient.sh ] || wget --progress=dot:mega -P "$TMP" -N "https://raw.githubusercontent.com/pkozelka/microtools/master/soap/SoapClient.sh" || exit 1
chmod +x "SoapClient.sh" && source "./SoapClient.sh"
SoapClient "$@"
