#!/bin/bash

REMOTE_URL="http://www.webservicex.net"
ENDPOINT_URI="/country.asmx"
ENDPOINT_WSDL="?WSDL"

function SOAP_GetCountriesRequest() {
    SoapEnvelope <<EOF
    <GetCountries xmlns="http://www.webserviceX.NET" />
EOF
}

function SOAP_GetCountryByCountryCodeRequest() {
    local countryCode="$1"
    cat <<EOF
<?xml version="1.0" encoding="utf-8"?>
<soap:Envelope xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/">
  <soap:Body>
    <GetCountryByCountryCode xmlns="http://www.webserviceX.NET">
      <CountryCode>${countryCode}</CountryCode>
    </GetCountryByCountryCode>
  </soap:Body>
</soap:Envelope>
EOF
}

function SOAP_GetISDRequest() {
    local countryName="$1"
    cat <<EOF
<?xml version="1.0" encoding="utf-8"?>
<soap:Envelope xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/">
  <soap:Body>
    <GetISD xmlns="http://www.webserviceX.NET">
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
