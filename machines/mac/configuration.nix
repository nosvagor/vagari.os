{ config, pkgs, inputs, ... }:

{
  imports = [
    ./hardware-configuration.nix 
    ../shared.nix
  ];

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  home-manager.users = {
    nosvagor = { };
    cullyn = { };
  };

  system.stateVersion = "24.05"; 
}
