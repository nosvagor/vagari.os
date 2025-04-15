{ config, pkgs, inputs, ... }:

{
  imports = [
    ./hardware-configuration.nix 
    ../shared.nix
    ../sddm.nix
  ];

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  home-manager.users = {
    nosvagor = { };
    cullyn = { };
  };

  hardware.graphics.enable = true;

  system.stateVersion = "24.05"; 
}
