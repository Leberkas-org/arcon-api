#!/bin/bash

# needed for bundling to single yaml file
npm install -g @redocly/cli@latest

# install python requirements
cat requirements.txt | xargs pipx install

# create symlinks to use scripts as command
parent_path=$( cd "$(dirname "${BASH_SOURCE[0]}")" ; pwd -P )

echo "Setup scripts in path ${parent_path}..."
sudo ln -s $parent_path/build.sh /usr/local/bin/bundleapi
sudo ln -s $parent_path/validate.sh /usr/local/bin/validateapi

# fix access rights
cd /usr/local/bin/
sudo chmod +x bundleapi validateapi
echo "Done"su