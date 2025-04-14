#!/bin/bash
cd $( cd "$(dirname "$(realpath "${BASH_SOURCE[0]}")")" ; pwd -P )/..
swagger-cli validate -o build/openapi.yml -t yaml src/api.yml