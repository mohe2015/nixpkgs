{ lib, stdenv, fetchurl, fetchFromGitHub, buildGoPackage, buildEnv, mattermost-server, mattermost-webapp }:

buildEnv {
  name = "mattermost-5.32.1";
  paths = [ mattermost-server mattermost-webapp ];

  extraOutputsToInstall = [ "config" ];

  meta = with lib; {
    description = "Open-source, self-hosted Slack-alternative";
    homepage = "https://www.mattermost.org";
    license = with licenses; [ agpl3 asl20 ];
    maintainers = with maintainers; [ fpletz ryantm ];
    platforms = platforms.unix;
  };
}
