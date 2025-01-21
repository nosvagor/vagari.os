{ config, pkgs, ... }:

{
  home.packages = [ pkgs.bitwarden-cli ];

  sops = {
    enable = true;
    defaultSopsFile = ../secrets/secrets.yaml;
    age = {
      keyFile = "/home/nosvagor/.config/sops/age/keys.txt";
      generateKey = true;
      keyFileName = "vagari-os.txt";
    };
  };
} 