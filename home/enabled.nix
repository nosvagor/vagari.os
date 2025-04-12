{ pkgs, config, inputs, hostname, ... }:
{
  imports = [ 
    ./modules/git.nix
    ./modules/zsh.nix
  ];
  home.stateVersion = "24.05";
}
