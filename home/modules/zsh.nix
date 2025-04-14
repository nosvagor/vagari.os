{ pkgs, hostname, ... }:
{
  programs.zsh = {
    enable = true;

    shellAliases = {
      clone = "git clone https://github.com/nosvagor/vagari.os.git && cd vagari.os && git pull origin hyprland && git checkout hyprland";
      spp = "git stash; git pull; git stash pop";
      rebuild = "sudo nixos-rebuild switch --flake .#${hostname}";
      ghcfg = "sudo nixos-generate-config --show-hardware-config > ./machines/${hostname}/hardware-configuration.nix && git add ./machines/${hostname}/hardware-configuration.nix && git commit -m 'Add hardware configuration for ${hostname}'";
    };

    enableCompletion = true;
    autosuggestion.enable = true;
    syntaxHighlighting.enable = true;

  };
}
