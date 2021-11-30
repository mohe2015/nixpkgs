#!/usr/bin/env bash

ROOT="$(realpath "$(dirname -- "$(readlink -f -- "${BASH_SOURCE[0]}")")"/../../../..)"

node2nix \
  --nodejs-16 \
  --node-env ../../../development/node-packages/node-env.nix \
  --development \
  --lock ./package-lock-temp.json \
  --output node-packages.nix \
  --composition node-composition.nix
