{ config, pkgs, inputs, ... }:

{
  imports = [
    ./hardware-configuration.nix
    ../shared.nix
  ];

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  boot.initrd.luks.devices."root" = {
    device = "/dev/disk/by-uuid/YOUR-UUID";
    allowDiscards = true;
  };

  networking.hostName = "abbot";

  home-manager.users = {
    nosvagor = { };
    cullyn = { };
  };

  system.stateVersion = "24.05";
}
