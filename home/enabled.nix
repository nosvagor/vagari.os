{ pkgs, config, inputs, hostname, ... }:
{
  imports = [ 
    ./modules/git.nix
    ./modules/zsh.nix
    ./modules/env.nix
    ./modules/hyprland.nix
  ];
  home.stateVersion = "24.05";
}