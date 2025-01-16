{ config, pkgs, ... }:

{
  imports = [
    ./modules/browser.nix
    ./modules/hyprland.nix
    ./modules/nvim.nix
    ./modules/ghostty.nix
    ./modules/theme.nix
  ];

  home = {
    username = "nosvagor";
    homeDirectory = "/home/nosvagor";
    stateVersion = "23.11";
  };

  programs.home-manager.enable = true;
} 