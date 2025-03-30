{ config, pkgs, ... }:

{
  # imports = [
  #   ./modules/browser.nix
  #   ./modules/hyprland.nix
  #   ./modules/editor.nix
  #   ./modules/theme.nix
  # ];

  home = {
    username = primaryUser;
    homeDirectory = "/home/${primaryUser}";
    stateVersion = "24.05";
  };
} 