#!/bin/bash

REMOTE_URL="http://www.webservicex.net"
ENDPOINT_URI="/country.asmx"
ENDPOINT_WSDL="?WSDL"

function SOAP_GetCountriesRequest() {
    cat <<EOF
<?xml version="1.0" encoding="utf-8"?>
<soap:Envelope xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/">
  <soap:Body>
    <GetCountries xmlns="http://www.webserviceX.NET" />
  </soap:Body>
</soap:Envelope>
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
    SOAP_GetCountriesRequest | $CURL_POST -d@-
}

function CMD_country() {
    SOAP_GetCountryByCountryCodeRequest "$@" | $CURL_POST -d@-
}

function CMD_isd() {
    SOAP_GetISDRequest "$@" | $CURL_POST -d@-
}

source "./SoapClient.sh"
SoapClient "$@"
