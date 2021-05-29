{ stdenvNoCC
, lib
, makeWrapper
, coreutils
, curl
, jq
, unzip
, nix
}:

stdenvNoCC.mkDerivation rec {
  pname = "nix-prefetch-openvsx";
  version = "0.1.0";

  src = ./nix-prefetch-openvsx;

  dontUnpack = true;

  nativeBuildInputs = [
    makeWrapper
  ];

  buildInputs = [
    coreutils
    curl
    jq
    unzip
    nix
  ];

  installPhase = ''
    runHook preInstall
    mkdir -p $out/bin
    cp $src $out/bin/${pname}
    chmod +x $out/bin/${pname}
    runHook postInstall
  '';

  postFixup = ''
    declare -a makeWrapperArgs=(
      --prefix PATH : "${lib.makeBinPath buildInputs}"
    )
    wrapProgram "$out/bin/${pname}" "''${makeWrapperArgs[@]}"
  '';

  meta = with lib; {
    description = "Prefetch vscode extensions from Open VSX Registry";
    license = licenses.mit;
    platforms = platforms.all;
    maintainers = with maintainers; [ ShamrockLee ];
  };
}
