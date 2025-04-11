{ config, pkgs, inputs, ... }:

{
  imports = [
    ./hardware-configuration.nix
    ../shared/core.nix
    ../shared/packages.nix
  ];

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  boot.initrd.luks.devices."root" = {
    device = "/dev/disk/by-uuid/YOUR-UUID";
    allowDiscards = true;
  };

  networking.hostName = "abbot";
  networking.networkmanager.enable = true;

  users.users.nosvagor = {
    isNormalUser = true;
    description = "nosvagor";
    extraGroups = [ "networkmanager" "wheel" ]; 
    shell = pkgs.zsh; 
  };

  programs.zsh.enable = true;

  security.sudo.enable = true;
  security.sudo.wheelNeedsPassword = true; 

  system.stateVersion = "24.05"; 

}
