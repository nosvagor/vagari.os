{ config, pkgs, ... }:
{
  security = {
    protectKernelImage = true;
    lockKernelModules = false;
    apparmor.enable = true;
    audit.enable = true;
    auditd.enable = true;
    pam.enableSSHAgentAuth = true;
    sudo.execWheelOnly = true;
  };

  # Secure boot integration (not full validation but safer practices)
  boot.loader = {
    systemd-boot = {
      consoleMode = "0";          # Disable boot menu for security
      editor = false;             # Prevent kernel parameter modification
    };
    efi = {
      efiSysMountPoint = "/boot/efi";  # Standard EFI partition location
      canTouchEfiVariables = false;    # Prevent modifying EFI variables
    };
  };

  # Kernel image protection
  security.protectKernelImage = true;  # Prevent modification of running kernel

  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 7d";
  };

  system.autoUpgrade = {
    enable = true;
    flake = "github:nosvagor/vagari.os";
    flags = [
      "--update-input" "nixpkgs"
      "--option" "build-use-sandbox" "true"
    ];
    dates = "04:00";
    randomizedDelaySec = "45min";
  };
} 