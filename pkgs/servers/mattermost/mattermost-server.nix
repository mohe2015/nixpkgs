{ lib, stdenv, fetchurl, fetchFromGitHub, buildGoPackage, buildEnv }:

buildGoPackage rec {
  pname = "mattermost-server";
  version = "5.32.1";

  src = fetchFromGitHub {
    owner = "mattermost";
    repo = "mattermost-server";
    rev = "v5.32.1";
    sha256 = "BssrTfkIxUbXYXIfz9i+5b4rEYSzBim+/riK78m8Bxo=";
  };

  goPackagePath = "github.com/mattermost/mattermost-server";

  buildFlagsArray = ''
    -ldflags=
      -X ${goPackagePath}/model.BuildNumber=nixpkgs-5.32.1
  '';

  outputs = [ "config" ];

  postBuild = ''
    cp $out/config/config.json $config
  '';

  meta = {
    outputsToInstall = [ "config" ];
  };
}