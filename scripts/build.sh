#!/bin/bash
cd $( cd "$(dirname "$(realpath "${BASH_SOURCE[0]}")")" ; pwd -P )/..

# create schema index file :)

echo "========== Generating schema index yml =========="

for file in src/schemas/*.yml
do
    file=${file##*/}
    if [[ "$file" != "index.yml" && "$file" != "*.yml" ]]; then
    
        name="${file::-4}"
        echo "    -> $name";
        result+="{"\"Name\"": "\"${name}\""},"
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

# bundle multi file api spec to single file
redocly bundle -o build/openapi.yml --ext yml src/api.yml

if [[ -n "$JINJA2_CONVERT" ]]; then
    # run jinja2 template
    echo "Converting Jinja2 tepmlate..."
    mv build/openapi.yml build/openapi.yml.tpl;
    envtpl build/openapi.yml.tpl;
    echo "Done."
fi


#set api version if not set

if [[ -n "$STATIC_HTML_DOCS" ]]; 
    then redocly build-docs -o build/api_doc.html build/openapi.yml; 
fi

redocly stats build/openapi.yml

#set api version if not set
if [[ -n "$OPEN_AFTER_BUILD" && "$OPEN_AFTER_BUILD" != "false" ]]; then
    echo "Open openapi.yml...."
    code -r build/openapi.yml; 
fi