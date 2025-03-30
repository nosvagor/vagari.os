#  █████╗ ██████╗ ██████╗  ██████╗ ████████╗
# ██╔══██╗██╔══██╗██╔══██╗██╔═══██╗╚══██╔══╝
# ███████║██████╔╝██████╔╝██║   ██║   ██║   
# ██╔══██║██╔══██╗██╔══██╗██║   ██║   ██║   
# ██║  ██║██████╔╝██████╔╝╚██████╔╝   ██║   
# ╚═╝  ╚═╝╚═════╝ ╚═════╝  ╚═════╝    ╚═╝   
# Portable AMD NUC development machine, focused on development.

{ config, pkgs, machineName, ... }:

{
  imports = [
    ./hardware-configuration.nix     # Generated hardware config
    ../shared/core.nix               # Shared core system settings
    ../shared/fonts.nix              # System-wide fonts
    ../shared/packages/base.nix      # Base packages
    ../shared/packages/build.nix     # Development tools
  ];

  # AMD-specific optimizations
  hardware.cpu.amd.updateMicrocode = true;
  hardware.opengl.extraPackages = with pkgs; [
    rocm-opencl-icd      
    rocm-opencl-runtime 
  ];

  boot.initrd.luks.devices = {
    root = {
      device = "/dev/disk/by-uuid/YOUR-UUID"; # <-- Actual placeholder
      preLVM = true;
    };
  };
} 