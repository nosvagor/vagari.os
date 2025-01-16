#  █████╗ ██████╗ ██████╗  ██████╗ ████████╗
# ██╔══██╗██╔══██╗██╔══██╗██╔═══██╗╚══██╔══╝
# ███████║██████╔╝██████╔╝██║   ██║   ██║   
# ██╔══██║██╔══██╗██╔══██╗██║   ██║   ██║   
# ██║  ██║██████╔╝██████╔╝╚██████╔╝   ██║   
# ╚═╝  ╚═╝╚═════╝ ╚═════╝  ╚═════╝    ╚═╝   
# Portable AMD NUC development machine, focused on development.
# Designed to deploy to any machine quickly.

{ config, pkgs, ... }:

{
  imports = [
    ./hardware-configuration.nix     # Generated hardware config
    ../shared/core.nix               # Shared core system settings
    ../shared/fonts.nix              # System-wide fonts
    ../shared/packages/base.nix      # Base packages
    ../shared/packages/build.nix     # Development tools
  ];

  # Machine identity
  networking.hostName = "abbot";
  networking.networkmanager.enable = true;

  # AMD-specific optimizations
  hardware.cpu.amd.updateMicrocode = true;
  hardware.opengl.extraPackages = with pkgs; [
    rocm-opencl-icd    # OpenCL support
    rocm-opencl-runtime
  ];

  # Build and compilation optimizations
  nix.settings = {
    max-jobs = "auto";             # Use all CPU cores for building
    cores = 0;                     # Use all CPU threads
  };

  # System performance tuning
  boot.kernel.sysctl = {
    "kernel.sched_autogroup_enabled" = 1;     # Better desktop responsiveness
    "vm.swappiness" = 10;                     # Reduce swap usage
  };

  powerManagement = {
    enable = true;
    cpuFreqGovernor = "performance";          # Maximum CPU performance
  };

  # Storage configuration
  boot.initrd.luks.devices = {
    root = {
      device = "/dev/disk/by-uuid/YOUR-UUID";  # TODO: Replace with actual UUID
      preLVM = true;
    };
  };

  fileSystems = {
    "/" = {
      device = "/dev/mapper/root";
      fsType = "btrfs";
      options = [ "subvol=@" "compress=zstd" "noatime" ];
    };
  };
} 