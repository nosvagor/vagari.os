# ██████╗ ██████╗ ███████╗████████╗███████╗██╗     ██╗      ██████╗ 
# ██╔════╝██╔═══██╗██╔════╝╚══██╔══╝██╔════╝██║     ██║     ██╔═══██╗
# ██║     ██║   ██║███████╗   ██║   █████╗  ██║     ██║     ██║   ██║
# ██║     ██║   ██║╚════██║   ██║   ██╔══╝  ██║     ██║     ██║   ██║
# ╚██████╗╚██████╔╝███████║   ██║   ███████╗███████╗███████╗╚██████╔╝
#  ╚═════╝ ╚═════╝ ╚══════╝   ╚═╝   ╚══════╝╚══════╝╚══════╝ ╚═════╝ 
# Main workstation configuration with full development environment.
# Includes gaming setup, content creation, and more powerful hardware configs.

{ config, pkgs, ... }:

{
  imports = [
    ./hardware-configuration.nix     # Generated hardware config
    ../shared/core.nix               # Shared core system settings
    ../shared/fonts.nix              # System-wide fonts
    ../shared/packages/base.nix      # Base packages
    ../shared/packages/build.nix     # Development tools
    ../shared/packages/create.nix    # Content creation
    ../shared/packages/game.nix      # Gaming packages
  ];

  # Machine identity
  networking.hostName = "costello";
  networking.networkmanager.enable = true;

  # Storage configuration (multiple drives)
  boot.initrd.luks.devices = {
    root = {
      device = "/dev/disk/by-uuid/YOUR-UUID";  # TODO: Replace with actual UUID
      preLVM = true;
    };
    games = {
      device = "/dev/disk/by-uuid/YOUR-GAMES-UUID";  # TODO: Replace with actual UUID
      preLVM = true;
    };
  };

  fileSystems = {
    "/" = {
      device = "/dev/mapper/root";
      fsType = "btrfs";
      options = [ "subvol=@" "compress=zstd" "noatime" ];
    };
    "/games" = {
      device = "/dev/mapper/games";
      fsType = "btrfs";
      options = [ "compress=zstd" "noatime" ];
    };
  };

  # Hardware acceleration and GPU support
  hardware.opengl = {
    enable = true;
    driSupport = true;
    driSupport32Bit = true;  # Needed for Steam
  };

  # Gaming optimizations
  boot.kernel.sysctl = {
    "vm.swappiness" = 10;                   # Reduce swap usage
    "vm.max_map_count" = 2147483642;        # Required by some games
  };

  # Power management for desktop
  services.power-profiles-daemon.enable = false;  # Using custom power settings
  services.thermald.enable = true;                # CPU thermal management
  powerManagement = {
    enable = true;
    cpuFreqGovernor = "performance";              # Full CPU power
  };
} 