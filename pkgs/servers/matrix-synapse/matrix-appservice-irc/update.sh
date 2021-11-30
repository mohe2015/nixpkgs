#!/usr/bin/env nix-shell
#! nix-shell -I nixpkgs=. -i bash -p nodejs-17_x curl jq nix yarn prefetch-yarn-deps

set -euo pipefail
# cd to the folder containing this script
cd "$(dirname "$0")"

CURRENT_VERSION=0.30.0
TARGET_VERSION="$(curl https://api.github.com/repos/matrix-org/matrix-appservice-irc/releases/latest | jq --exit-status -r ".tag_name")"

echo "matrix-appservice-irc: $CURRENT_VERSION -> $TARGET_VERSION"

rm -f package.json package-lock.json yarn.lock
wget https://github.com/matrix-org/matrix-appservice-irc/raw/$TARGET_VERSION/package.json
wget https://github.com/matrix-org/matrix-appservice-irc/raw/$TARGET_VERSION/package-lock.json
yarn import
yarn_hash=$(prefetch-yarn-deps yarn.lock)
echo $yarn_hash