{ config, pkgs, ... }:

{
  imports = [
    ./modules/browser.nix
    ./modules/hyprland.nix
    ./modules/editor.nix
    ./modules/theme.nix
  ];
} 