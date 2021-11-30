#!/usr/bin/env nix-shell
#! nix-shell -I nixpkgs=. -i bash -p nodePackages.node2nix nodejs-16_x curl jq nix

set -euo pipefail
# cd to the folder containing this script
cd "$(dirname "$0")"

CURRENT_VERSION=0.30.0
TARGET_VERSION="$(curl https://api.github.com/repos/matrix-org/matrix-appservice-irc/releases/latest | jq --exit-status -r ".tag_name")"

echo "matrix-appservice-irc: $CURRENT_VERSION -> $TARGET_VERSION"

rm -f package.json package-lock.json
wget https://github.com/matrix-org/matrix-appservice-irc/raw/$TARGET_VERSION/package.json
wget -O package-lock-temp.json https://github.com/matrix-org/matrix-appservice-irc/raw/$TARGET_VERSION/package-lock.json

# Apparently this is done by r-ryantm, so only uncomment for manual usage
#git add ./package.json ./node-packages.nix
#git commit -m "matrix-appservice-irc: ${CURRENT_VERSION} -> ${TARGET_VERSION}"
