{ stdenv, lib, fetchFromGitHub, nodejs, mkYarnPackage, yarn2nix-moretea }:

# nix-shell -p yarn yarn2nix nodejs python3 nixpkgs#nodePackages.node2nix
# yarn install
# yarn2nix > yarn.nix
# npm install
# node2nix

# https://nixos.wiki/wiki/Nixpkgs/Create_and_debug_packages
# nix develop .#peertube
# typeset -f genericBuild | less
# NIX_LOG_FD=1 genericBuild

# nano scripts/build/index.sh

mkYarnPackage rec {
  pname = "peertube";
  version = "3.2.0-rc.1";

  nativeBuildInputs = [ nodejs ];

  src = fetchFromGitHub {
    owner = "Chocobozzz";
    repo = "PeerTube";
    rev = "v${version}";
    sha256 = "clYGnspQhY7255YsTNiUB/zZlr5oBtB9zewl/T1bO1g=";
  };

  yarnNix = ./yarn.nix;
  yarnFlags = yarn2nix-moretea.defaultYarnFlags ++ [ "--production" ];

  buildPhase = ''
    yarn build
  '';
}