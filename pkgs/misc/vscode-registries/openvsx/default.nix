{ lib
, vscode-registry-commons
, callPackage
, fetchurl
, spdxLicense ? yarn2nix.spdxLicense
, yarn2nix
, overlays ? [ ]
}:

with vscode-registry-commons;
with registry-lib;

let
  ## The all-extension-raw.json is fetched from
  ## https://open-vsx.org/api/-/search?includeAllVersions=false&offset=0&size=2000
  ## The registry-reference-list.json is generated using
  ## jq -r '.extensions[] | [ .namespace, .name, .version] | @sh | "nix-prefetch-openvsx " + . + "; echo ,"' ./all-extensions-raw.json | xargs -I{} bash -c "{}" | tee -a registry-reference-list.json
  ## plus mamual corrections
  ## both are formatted using jq
  ## TODO: Automate the bootstrap and update
  ## API reference: https://open-vsx.org/swagger-ui/

  registry-reference-list =
    builtins.fromJSON (builtins.readFile ./registry-reference-list.json);

  base = final: {
    registry-reference-attrs-raw = registryRefListToAttrs registry-reference-list;

    domain = "https://open-vsx.org";

    getVsixUrl = (registry-reference@{ domain ? final.domain
                  , publisher
                  , name
                  , version
                  , ...
                  }:
      "${domain}/api/${publisher}/${name}/${version}/file/${publisher}.${name}-${version}.vsix");
    registryRefAttrnames = [ "name" "publisher" "version" "sha256" ];
    registry-reference-attrs =
      (mapRegistryRefAttrs (lib.getAttrs final.registryRefAttrnames)
        final.registry-reference-attrs-raw);

    meta-attrs = mapRegistryRefAttrs
      (ref:
        (getExistingAttrs [ "description" "homepage" ] ref)
        // lib.optionalAttrs (builtins.hasAttr "license-raw" ref) {
          license = lib.getLicenseFromSpdxId ref.license-raw;
        })
      final.registry-reference-attrs-raw;

    mkExtensionFromRefSimple = registryRef:
      let
        builder =
          if (lib.hasAttrByPath [ (escapeAttrPrefix registryRef.publisher) (escapeAttrPrefix registryRef.name) ] make-extension-attrs)
          then make-extension-attrs."${escapeAttrPrefix registryRef.publisher}"."${escapeAttrPrefix registryRef.name}"
          else mkExtensionGeneral;
      in
      builder {
        inherit registryRef;
        vsix = fetchurl {
          url = final.getVsixUrl {
            inherit (final) domain;
            inherit (registryRef) publisher name version;
          };
          inherit (registryRef) sha256;
        };
        meta = final.meta-attrs."${escapeAttrPrefix registryRef.publisher}"."${escapeAttrPrefix registryRef.name}";
      };

    extensions = recurseIntoExtensionAttrs (mapRegistryRefAttrs final.mkExtensionFromRefSimple final.registry-reference-attrs);

    mkExtensionFromRef = registryRef: (
      final.mkExtensionFromRefSimple
        (lib.getAttrs final.registryRefAttrnames registryRef)
    ).override
      (removeAttrs final.registryRefAttrnames registryRef);
  };

  default_overlays = [ ];

in
lib.fix (lib.foldl' (lib.flip lib.extends) base (default_overlays ++ overlays))
