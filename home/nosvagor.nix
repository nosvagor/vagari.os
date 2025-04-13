{ pkgs, hostname, ... }:
{
  imports = [
    ./enabled.nix 
  ];

  programs.git = {
    userName = "nosvagor";
    userEmail = "cullyn@nosvagor.com";
    gpg.allowedSignersFile = "/home/nosvagor/.ssh/allowed_signers";
  };
  home.file.".ssh/allowed_signers".text = ''
    cullyn@nosvagor.com ssh-ed25519 <your-public-key>
  '';

}
