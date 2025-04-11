# machines/shared/packages.nix
{ config, pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    git   
    curl 
    neovim
    htop
  ];
}
