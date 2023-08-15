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
  pkgsMySystem.runCommand "test"
  {
    name = "btrfs.img${lib.optionalString compressImage ".zst"}";

    nativeBuildInputs = with pkgsMySystem; [ btrfs-progs libfaketime perl fakeroot util-linux ]
      ++ lib.optional compressImage zstd;

    QEMU_OPTS = "-drive file=$out,format=raw,if=virtio,cache=unsafe,werror=report";

    memSize = 1024;

    preVM = ''
      set -ex
      touch $out
      ${pkgsMySystem.qemu_kvm}/bin/qemu-img create -f raw $out 8192M
    '';

    postVM = ''
      ls -la $out
    '';
  }

    ''
      set -ex
      mknod /dev/btrfs-control c 10 234
      mkdir /mnt
      mkfs.btrfs --verbose --label ${volumeLabel} --uuid ${uuid} --checksum xxhash --data single --metadata dup /dev/${pkgsMySystem.vmTools.hd}
      # compress-force=zstd     Used:  870.09MiB
      # compress-force=zstd:15  Used:  839.05MiB 806.78MiB
      # compress-force=zlib:9   Used:  860.03MiB
      # compress-force=lzo      Used: 1017.20MiB
      # none                    Used:    1.44GiB 1.33GiB
      mount -o compress-force=zstd /dev/${pkgsMySystem.vmTools.hd} /mnt

      (
      mkdir -p ./files
      ${populateImageCommands} # will probably populate # ./files/boot
      )

      mkdir -p /mnt/nix/store

      xargs -I % cp -dR % -t /mnt/nix/store/ < ${sdClosureInfo}/store-paths
      ls -la  /mnt/nix/store/
      (
        GLOBIGNORE=".:.."
        shopt -u dotglob

        for f in ./files/*; do
            cp -a -t /mnt/ "$f"
        done
      )

      # Also include a manifest of the closures in a format suitable for nix-store --load-db
      cp ${sdClosureInfo}/registration /mnt/nix-path-registration

      btrfs filesystem usage /mnt

      #${pkgsMySystem.duperemove}/bin/duperemove -q -r -d /mnt

      #btrfs filesystem usage /mnt

      umount /mnt
    ''

)
