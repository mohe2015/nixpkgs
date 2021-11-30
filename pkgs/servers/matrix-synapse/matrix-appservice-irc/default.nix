{ pkgs, stdenv, nodePackages, makeWrapper, nixosTests, nodejs-16_x, stdenv, lib, fetchFromGitHub }:

stdenv.mkDerivation {
  pname = "matrix-appservice-irc";
  version = "0.32.1";

  src = fetchFromGitHub {
    owner = "matrix-org";
    repo = "matrix-appservice-irc";
    rev = version;
    sha256 = "";
  };

  yarnOfflineCache = fetchYarnDeps {
    yarnLock = ./yarn.lock;
    sha256 = "03cbyxww395nkmjbs7nyjky0ldqrcl7bxqka4waqbk7yw2yil7xm";
  };

  nativeBuildInputs = [ makeWrapper nodePackages.node-gyp-build ];

  postInstall = ''
    makeWrapper '${nodejs-16_x}/bin/node' "$out/bin/matrix-appservice-irc" \
      --add-flags "$out/lib/node_modules/matrix-appservice-irc/app.js"
  '';

  passthru.tests.matrix-appservice-irc = nixosTests.matrix-appservice-irc;
  passthru.updateScript = ./update.sh;

  meta = with lib; {
    description = "Node.js IRC bridge for Matrix";
    maintainers = with maintainers; [ ];
    homepage = "https://github.com/matrix-org/matrix-appservice-irc";
    license = licenses.asl20;
  };
}
