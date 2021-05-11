{ stdenv, lib, fetchFromGitHub, mkYarnPackage, yarn2nix-moretea }:

# nix-shell -p yarn yarn2nix nodejs python3
# yarn install --production
# yarn2nix > yarn.nix

mkYarnPackage rec {
  pname = "peertube";
  version = "3.2.0-rc.1";

  src = fetchFromGitHub {
    owner = "Chocobozzz";
    repo = "PeerTube";
    rev = "v${version}";
    sha256 = "clYGnspQhY7255YsTNiUB/zZlr5oBtB9zewl/T1bO1g=";
  };

  yarnNix = ./yarn.nix;
  yarnFlags = yarn2nix-moretea.defaultYarnFlags ++ [ "--production" ];
}