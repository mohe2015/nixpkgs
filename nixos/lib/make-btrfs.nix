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

  nativeBuildInputs = with pkgsBuildBuild; [ btrfs-progs libfaketime perl fakeroot util-linux ]
  ++ lib.optional compressImage zstd;

  buildCommand =
    ''
      ${if compressImage then "img=temp.img" else "img=$out"}
      (
      mkdir -p ./files
      ${populateImageCommands}
      )

      echo "Preparing store paths for image..."

      # Create nix/store before copying path
      mkdir -p ./rootImage/nix/store

      xargs -I % cp -a --reflink=auto % -t ./rootImage/nix/store/ < ${sdClosureInfo}/store-paths
      (
        GLOBIGNORE=".:.."
        shopt -u dotglob

        for f in ./files/*; do
            cp -a --reflink=auto -t ./rootImage/ "$f"
        done
      )

      # Also include a manifest of the closures in a format suitable for nix-store --load-db
      cp ${sdClosureInfo}/registration ./rootImage/nix-path-registration

      # Make a crude approximation of the size of the target image.
      # If the script starts failing, increase the fudge factors here.
      numInodes=$(find ./rootImage | wc -l)
      numDataBlocks=$(du -s -c -B 4096 --apparent-size ./rootImage | tail -1 | awk '{ print int($1 * 1.10) }')
      bytes=$((2 * 4096 * $numInodes + 4096 * $numDataBlocks))
      echo "Creating an BTRFS image of $bytes bytes (numInodes=$numInodes, numDataBlocks=$numDataBlocks)"

      truncate -s $bytes $img

      # TODO FIXME btrfs compression
      # --rootdir ./rootImage --shrink
      faketime -f "1970-01-01 00:00:01" fakeroot mkfs.btrfs --verbose --label ${volumeLabel} --uuid ${uuid} --checksum xxhash --data single --metadata dup $img

      mountPoint=$(mktemp -d)

      mount -o compress-force=zstd $img $mountPoint

      cp -r ./rootImage/ $mountPoint

      btrfs filesystem du $mountPoint
      btrfs filesystem usage $mountPoint

      # TODO duperemove

      fakeroot umount $mountPoint

      # rather use the unallocated value
      # sudo btrfs filesystem usage -b /mountpoint
      #btrfs filesystem resize max $img
      #truncate -s +16M $img

      if [ ${builtins.toString compressImage} ]; then
        echo "Compressing image"
        zstd -v --no-progress ./$img -o $out
      fi
    '';
})