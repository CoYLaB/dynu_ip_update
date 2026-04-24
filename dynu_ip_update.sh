#!/usr/bin/env bash
#
# Simple script to update the Dynu A records for a host
# with the IP of the current machine. The host name
# is retrieved from the configuration file dynu.cfg
# located in the same directory. The configuration
# file also contains the Dynu API token for making the
# relevant API calle for updating the record.
# 
# 

# Script directory
SHELL_PROCESS=`ps -p $$ | sed -n 2p`
if [[ "${SHELL_PROCESS}" == *"zsh"* ]]; then
  RELEVANT_BASH_SOURCE="${(%):-%N}"
else
  RELEVANT_BASH_SOURCE="${BASH_SOURCE[0]}"
fi
SCRIPT_DIR=$( cd -- "$( dirname -- "${RELEVANT_BASH_SOURCE}" )" >/dev/null 2>&1 ; pwd -P )

# IP Info Site
IP_INFO="ipinfo.io/ip"

# API Requests
API_CHECK="https://api.dynu.com/v2/dns/getroot/"
API_UPDATE="https://api.dynu.com/v2/dns"

# Extract API call status code & error type
parse_api_response() {
        local response="${1}"
        # echo "RESPONSE:    ${response}"
        status=$( jq -r ".statusCode" <<< ${response} )
        # echo "STATUS CODE: ${status}"
        if [[ ${status} != 200 ]]; then
                type=$( jq -r ".type" <<< ${response} )
                # echo "TYPE:        ${type}"
        fi
}

# Header
echo "+--------------------+"
echo "| Updating Dynu DDNS |"
echo "+--------------------+"
echo

# Checking/Installing dependencies
j_path=$( command -v jq )
if [[ $? -ne 0  ]]; then
        echo "Installing jq"
        sudo yum install jq -y &> /dev/null
else
        echo "Found jq  : ${j_path}"
fi
c_path=$( command -v curl )
if [[ $? -ne 0 ]]; then
        echo "Installing curl"
        sudo yum install curl -y &> /dev/null
else
        echo "Found curl: ${c_path}"
fi
echo

# Read Dynu config file
echo "Reading config file..."
if [[ -e ${SCRIPT_DIR}/dynu.cfg ]]; then
  source "${SCRIPT_DIR}/dynu.cfg"
else
  >&2 echo "ERROR: No config file found. Create ${SCRIPT_DIR}/dynu.cfg (cf README.txt for more info)"
  exit 1
fi

if [[ -z ${API_TOKEN} || -z ${HOST_NAME} ]]; then
  >&2 echo "ERROR: Could not read config file ${SCRIPT_DIR}/dynu.cfg (cf README.txt for more info)"
  exit 1
fi

# Display config
echo "API TOKEN:   ${API_TOKEN}"
echo "HOSTNAME:    ${HOST_NAME}" 

# Get public IP v4
ip=$( curl \
        --silent \
        --request GET \
        "${IP_INFO}" )
if [[ $? -ne 0 ]]; then
        >&2 echo "ERROR: Could not get IP address from ${IP_INFO}"
        exit 1
fi

echo "IP:          ${ip}"
echo

# Check DNS record 
request="${API_CHECK}${HOST_NAME}"
response=$( curl \
                --silent \
                --header "accept: application/json" \
                --header "API-Key: ${API_TOKEN}" \
                --request GET "${request}" )
if [[ $? -ne 0 ]]; then
        >&2 echo "ERROR: Request ${API_CHECK}${HOST_NAME} failed"
        exit 1
fi
parse_api_response "${response}"
if [[ "${status}" == "200" ]]; then
        id=$( jq -r ".id" <<< ${response} )
fi

case ${status} in
        200)
                echo "Found A record for ${HOST_NAME} with id ${id}"
                echo "Updating it with ip ${ip}"
                request="${API_UPDATE}/${id}"
                response=$( curl \
                                --silent \
                                --header "accept: application/json" \
                                --header "content-type: application/json" \
                                --header "API-Key: ${API_TOKEN}" \
                                --request POST "${request}" \
                                --data "{ \"name\": \"${HOSTNAME}\", \"ipv4Address\": \"${ip}\" }" )
                ;;
        501)
                echo "Found no A record for ${HOST_NAME}"
                echo "Creating new one with ip ${ip}"
                request="${API_UPDATE}"
                response=$( curl \
                                --silent \
                                --header "accept: application/json" \
                                --header "content-type: application/json" \
                                --header "API-Key: ${API_TOKEN}" \
                                --request POST "${API_UPDATE}" \
                                --data "{ \"name\": \"${HOST_NAME}\", \"ipv4Address\": \"${ip}\" }" )
                ;;
        401|404|500|502)
                echo "STATUS CODE: ${status} FAILURE: ${type}"
                exit 1
                ;;
esac

echo
if [[ $? -ne 0 ]]; then
        >&2 echo "ERROR: Request ${request} failed"
        exit 1
fi
parse_api_response "${response}"
if [[ ${status} == 200 ]]; then
        echo "SUCCESS"
        exit 0
else
        >&2 echo "FAILURE ${status}: ${type}"
        exit 1
fi
