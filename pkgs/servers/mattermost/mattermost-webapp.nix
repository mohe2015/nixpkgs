{ lib, stdenv, fetchurl, fetchFromGitHub, buildGoPackage, buildEnv }:

stdenv.mkDerivation {
  pname = "mattermost-webapp";
  version = "5.32.1";

  src = fetchurl {
    url = "https://releases.mattermost.com/5.32.1/mattermost-5.32.1-linux-amd64.tar.gz";
    sha256 = "kRerl3fYRTrotj86AIFSor3GpjhABkCmego1ms9HmkQ=";
  };

  installPhase = ''
    mkdir -p $out
    tar --strip 1 --directory $out -xf $src \
      mattermost/client \
      mattermost/i18n \
      mattermost/fonts \
      mattermost/templates \
      mattermost/config
  '';
}