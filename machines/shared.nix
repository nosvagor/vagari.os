{ config, pkgs, inputs, ... }:

{
  users = {
    users = {
      nosvagor = {
        isNormalUser = true;
        description = "nosvagor";
        extraGroups = [ "wheel" "networkmanager" "audio" "video" "docker" ];
        shell = pkgs.zsh; 
        initialPassword = "hunter1"; 
      };
      cullyn = {
        isNormalUser = true;
        description = "cullyn";
        extraGroups = [ "wheel" "networkmanager" "audio" "video" "docker" ];
        shell = pkgs.zsh; 
        initialPassword = "hunter1"; 
      };
    };
  };
  security.sudo.enable = true;
  security.sudo.wheelNeedsPassword = false; 

  programs.zsh.enable = true;
  networking.networkmanager.enable = true;

  swapDevices = [{
    device = "/.swap/swapfile";
    size = 4096; 
  }];
  boot.initrd.systemd.enable = true; 

  fileSystems = {
    "/home" = {
      fsType = "btrfs";
      options = [ "subvol=@home" "compress=zstd" "noatime" "space_cache=v2" "autodefrag" ];
    };
    "/nix" = {
      fsType = "btrfs";
      options = [ "subvol=@nix" "compress=zstd" "noatime" "nodev" "space_cache=v2" ];
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

  time.timeZone = "America/Los_Angeles";
  i18n.defaultLocale = "en_US.UTF-8";

  nix.settings = {
    experimental-features = [ "nix-command" "flakes" ];
    auto-optimise-store = true;
  };

  services.btrfs.autoScrub = {
    enable = true;
    interval = "weekly";
  };

  environment.systemPackages = with pkgs; [
    curl 
    htop
    ripgrep 
    neofetch
    vim
  ];

  nixpkgs.config.allowUnfree = true;
  system.stateVersion = "24.05"; 
}
