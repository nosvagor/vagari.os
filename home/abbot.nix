{ config, pkgs, ... }:

{
  imports = [
    ./modules/browser.nix
    ./modules/hyprland.nix
    ./modules/editor.nix
    ./modules/theme.nix
  ];

  # Configure Home Manager itself
  home = {
    username = "nosvagor";
    homeDirectory = "/home/nosvagor";
    stateVersion = "23.11";
  };
} 