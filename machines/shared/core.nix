{ config, pkgs, ... }:

{
  fileSystems = {
    "/home" = {
      fsType = "btrfs";
      options = [ "subvol=@home" "compress=zstd" "noatime" "space_cache=v2" "autodefrag" ];
    };

    "/nix" = {
      fsType = "btrfs";
      options = [ "subvol=@nix" "compress=zstd" "noatime" "nodev" "space_cache=v2" ]; # nodev is good practice for /nix
    };

    "/.snapshots" = {
      fsType = "btrfs";
      options = [ "subvol=@snapshots" "compress=zstd" "noatime" "space_cache=v2" ];
    };

    "/.swap" = {
      fsType = "btrfs";
      options = [ "subvol=@swap" "compress=zstd" "noatime" "space_cache=v2" ];
    };
  };

  swapDevices = [{
    device = "/.swap/swapfile"; 
    size = 4096; 
  }];
  boot.initrd.systemd.enable = true;

  services.btrfs.autoScrub = {
    enable = true;
    interval = "weekly";
  };
}
