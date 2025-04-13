{ pkgs, hostname, ... }:
{
  imports = [
    ./enabled.nix 
  ];

  programs.git = {
    userName = "nosvagor";
    userEmail = "cullyn@nosvagor.com";
  };
}
