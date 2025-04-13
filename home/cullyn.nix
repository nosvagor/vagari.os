{ pkgs, hostname, ... }: 
{
  imports = [
    ./enabled.nix 
  ];

  programs.git = {
    userName = "cullyn";
    userEmail = "cullyn@trendcaptial.com";
    gpg.allowedSignersFile = "/home/cullyn/.ssh/allowed_signers";
  };
  home.file.".ssh/allowed_signers".text = ''
    cullyn@trendcaptial.com ssh-ed25519 <your-public-key>
  '';
}

