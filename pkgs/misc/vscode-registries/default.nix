{ lib, callPackage }:
{
  # vscode-marketplace = lib.recurseIntoAttrs (callPackage ./vscode-marketplace { });
  openvsx = lib.recurseIntoAttrs (callPackage ./openvsx { });
  # upstream-release = lib.recurseIntoAttrs (callPackage ./upstream-release { });
  # standalone = lib.recurseIntoAttrs (callPackage ./standalone { });
}
