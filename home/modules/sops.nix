{ config, pkgs, ... }:

{
  sops = {
    enable = true;
    defaultSopsFile = ../secrets/secrets.yaml;
    age.keyFile = "/home/nosvagor/.config/sops/age/keys.txt";
  };
} 