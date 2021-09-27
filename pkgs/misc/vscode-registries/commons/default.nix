{ lib, callPackage }:
{
  registry-lib = import ./registry-lib.nix { inherit lib; };

  mkExtensionGeneral = callPackage ./make-extension-general.nix { };

  unpackVsixHook = callPackage ./unpack-vsix-hook { };

  make-extension-attrs = { };
}
