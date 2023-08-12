# Builds an BTRFS image containing a populated /nix/store with the closure
# of store paths passed in the storePaths parameter, in addition to the
# contents of a directory that can be populated with commands. The
# generated image is sized to only fit its contents, with the expectation
# that a script resizes the filesystem at boot time.
{ pkgs
, pkgsBuildBuild
, lib
# List of derivations to be included
, storePaths
# Whether or not to compress the resulting image with zstd
, compressImage ? false
# Shell commands to populate the ./files directory.
# All files in that directory are copied to the root of the FS.
, populateImageCommands ? ""
, volumeLabel
, uuid ? "44444444-4444-4444-8888-888888888888"
}:

# https://discourse.nixos.org/t/run-nixos-aarch64-vm-on-x86-fails-even-with-binfmt/23124/4
# double emulation unfortunately
# https://github.com/NixOS/nixpkgs/blob/aefe566f73164776003ef5ef78003b5f9ccd7c4f/pkgs/top-level/stage.nix#L27
let
  sdClosureInfo = pkgs.buildPackages.closureInfo { rootPaths = storePaths; };
  pkgsMySystem = (import ./../.. { system = "x86_64-linux"; });
in
pkgsMySystem.vmTools.runInLinuxVM (
pkgsMySystem.stdenv.mkDerivation {
  name = "btrfs.img${lib.optionalString compressImage ".zst"}";

  nativeBuildInputs = with pkgsMySystem; [ btrfs-progs libfaketime perl fakeroot util-linux ]
  ++ lib.optional compressImage zstd;

  preVM = pkgsMySystem.vmTools.createEmptyImage { size = 4096; fullName = "test"; };

  buildCommand =
    ''
      mkdir /mnt
      mkfs.btrfs --verbose --label ${volumeLabel} --uuid ${uuid} --checksum xxhash --data single --metadata dup /dev/${pkgsMySystem.vmTools.hd}
      mount -o compress-force=zstd /dev/${pkgsMySystem.vmTools.hd} /tmp

      (
      mkdir -p ./files
      ${populateImageCommands} # will probably populate # ./files/boot
      )

      mkdir -p /mnt/nix/store

      xargs -I % cp -a --reflink=auto % -t /mnt/nix/store/ < ${sdClosureInfo}/store-paths
      (
        GLOBIGNORE=".:.."
        shopt -u dotglob

        for f in ./files/*; do
            cp -a --reflink=auto -t /mnt/ "$f"
        done
      )

      # Also include a manifest of the closures in a format suitable for nix-store --load-db
      cp ${sdClosureInfo}/registration /mnt/nix-path-registration

      btrfs filesystem du /mnt
      btrfs filesystem usage /mnt

      # TODO duperemove

      umount /mnt
    '';
})