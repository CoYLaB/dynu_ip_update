#! /bin/bash

# API Requests
API_CHECK="https://api.dynu.com/v2/dns/getroot/"
API_UPDATE="https://api.dynu.com/v2/dns"

# Extract API call status code & error type
API_response() {
        # echo "RESPONSE:    $1"
        status=$(jq -r ".statusCode" <<< $1)
        # echo "STATUS CODE: ${status}"
        if [[ "${status}" != "200" ]]; then
                type=$(jq -r ".type" <<< $1)
                # echo "TYPE:        ${type}"
        fi
}

# Header
echo "+--------------------+"
echo "| Updating Dynu DDNS |"
echo "+--------------------+"
echo

# Checking/Installing dependencies
j_path=$(command -v jq)
if [ $? -ne 0  ]; then
        echo "Installing jq"
        sudo yum install jq -y &> /dev/null
else
        echo "Found jq  : ${j_path}"
fi
c_path=$(command -v curl)
if [ $? -ne 0 ]; then
        echo "Installing curl"
        sudo yum install curl -y &> /dev/null
else
        echo "Found curl: ${c_path}"
fi
echo

# Read Dynu config file
source ./dynu.cfg

# Display config
echo "API TOKEN:   ${API_TOKEN}"
echo "HOSTNAME:    ${HOST_NAME}" 

# Get public IP v4
ip=$(curl --silent -X GET ipinfo.io/ip)
echo "IP:          ${ip}"

echo

# Check DNS record 
request="${API_CHECK}${HOST_NAME}"
response=$(curl \
                --silent \
                -X GET "${request}" \
                -H "accept: application/json" \
                -H "API-Key: ${API_TOKEN}")
if [ $? -ne 0 ]; then
        echo "ERROR: Request ${API_CHECK}${HOST_NAME} failed"
        exit 1
fi
API_response "${response}"
if [[ "${status}" == "200" ]]; then
        id=$(jq -r ".id" <<< ${response})
        # echo "ID:          ${id}"
fi

case ${status} in
        200)
                echo "Found A record for ${HOST_NAME} with id ${id}"
                echo "Updating it with ip ${ip}"
                request="${API_UPDATE}/${id}"
                response=$(curl \
                                --silent \
                                -X POST "${request}" \
                                -H "accept: application/json" \
                                -H "content-type: application/json" \
                                -H "API-Key: ${API_TOKEN}" \
                                -d "{ \"name\": \"${HOSTNAME}\", \"ipv4Address\": \"${ip}\" }")
                ;;
        501)
                echo "Found no A record for ${HOST_NAME}"
                echo "Creating new one with ip ${ip}"
                request="${API_UPDATE}"
                response=$(curl \
                                --silent \
                                -X POST "${API_UPDATE}" \
                                -H "accept: application/json" \
                                -H "content-type: application/json" \
                                -H "API-Key: ${API_TOKEN}" \
                                -d "{ \"name\": \"${HOST_NAME}\", \"ipv4Address\": \"${ip}\" }")
                ;;
        401|404|500|502)
                echo "STATUS CODE: ${status} FAILURE: ${type}"
                exit 1
                ;;
esac

echo
if [ $? -ne 0 ]; then
        echo "ERROR: Request ${request} failed"
        exit 1
fi
API_response "${response}"
if [[ ${status} == "200" ]]; then
        echo "SUCCESS"
        exit 0
else
        echo "FAILURE ${status}: ${type}"
        exit 1
fi;                                                                                                                                                                114,1         Bo
