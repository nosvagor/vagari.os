{ pkgs, hostname, ... }: 
{
  imports = [
    ./enabled.nix 
  ];

  programs.git = {
    userName = "cullyn";
    userEmail = "cullyn@trendcaptial.com";
  };
}

