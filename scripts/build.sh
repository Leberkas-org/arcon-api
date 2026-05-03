#!/bin/bash
cd $( cd "$(dirname "$(realpath "${BASH_SOURCE[0]}")")" ; pwd -P )/..

# ==================== Set API version ====================
export API_VERSION="${API_VERSION:-local-dev}"
echo "========== API Version: $API_VERSION =========="

# ==================== Generate schema index ====================
echo "========== Generating schema index yml =========="

for file in src/schemas/*.yml
do
    file=${file##*/}
    if [[ "$file" != "index.yml" && "$file" != "*.yml" ]]; then

        name="${file::-4}"
        echo "    -> $name";
        result+="{\"Name\": \"${name}\"},"
    fi
done

if [[ "$result" != "" ]]; then
    result="[${result::-1}]"
    FOO=$result envtpl --keep-template src/schemas/index.yml.tpl;
    echo "========== DONE =========="
else
    echo "    SKIP - No files found"
    rm -f src/schemas/index.yml
fi

# ==================== Bundle ====================
mkdir -p build
redocly bundle -o build/openapi.yml --ext yml src/api.yml

# ==================== Resolve version placeholder ====================
cp build/openapi.yml build/openapi.yml.tpl
envtpl build/openapi.yml.tpl

if [[ -n "$STATIC_HTML_DOCS" ]];
    then redocly build-docs -o build/api_doc.html build/openapi.yml;
fi

redocly stats build/openapi.yml
