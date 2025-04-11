{ config, pkgs, ... }:

{
  
  fileSystems = {

    "/home" = {
      device = "/dev/mapper/root"; 
      fsType = "btrfs";
      options = [ "subvol=@home" "compress=zstd" "noatime" "space_cache=v2" "autodefrag" ];
    };

    "/nix" = {
      device = "/dev/mapper/root"; 
      fsType = "btrfs";
      options = [ "subvol=@nix" "compress=zstd" "noatime" "nodev" "space_cache=v2" ]; # nodev is good practice for /nix
    };

    "/.snapshots" = {
      device = "/dev/mapper/root";
      fsType = "btrfs";
      options = [ "subvol=@snapshots" "compress=zstd" "noatime" "space_cache=v2" ];
    };

    "/.swap" = {
      device = "/dev/mapper/root"; 
      fsType = "btrfs";
      options = [ "subvol=@swap" "compress=zstd" "noatime" "space_cache=v2" ];
    };
  };

  swapDevices = [{
    device = "/.swap/swapfile"; 
    size = 4096; 
  }];

  systemd.services.create-swap = {
    description = "Create swap file for BTRFS";
    wantedBy = [ "swap-swapfile.swap" ]; 
    serviceConfig.Type = "oneshot";
    script = ''
      set -e
      SWAP_FILE="/.swap/swapfile"

      if [ ! -d "$(dirname "$SWAP_FILE")" ]; then
        echo "Swap directory $(dirname "$SWAP_FILE") not found!" >&2
        exit 1
      fi

      if ! [ -f "$SWAP_FILE" ]; then
        echo "Creating BTRFS swapfile at $SWAP_FILE..."
        truncate -s 0 "$SWAP_FILE"
        chattr +C "$SWAP_FILE" || { echo "Failed to set No_COW attribute on $SWAP_FILE" >&2; exit 1; }
        btrfs property set "$SWAP_FILE" compression none
        fallocate -l 4096M "$SWAP_FILE" || dd if=/dev/zero of="$SWAP_FILE" bs=1M count=4096 status=progress
        chmod 0600 "$SWAP_FILE"
        mkswap "$SWAP_FILE"
        echo "Swapfile created."
      else
        echo "Swapfile $SWAP_FILE already exists."
        chattr +C "$SWAP_FILE" || echo "Warning: Failed to ensure No_COW attribute on existing $SWAP_FILE" >&2
      fi
    '';
  };

  services.btrfs.autoScrub = {
    enable = true;
    interval = "weekly";
  };

}
