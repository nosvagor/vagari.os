{ pkgs, hostname, ... }:
{
  programs.zsh = {
    enable = true;

    shellAliases = {
      generate-hardware-config = "sudo nixos-generate-config --show-hardware-config > ./machines/${hostname}/hardware-configuration.nix && git add ./machines/${hostname}/hardware-configuration.nix && git commit -m 'Add hardware configuration for ${hostname}'";
      init = "git clone https://github.com/nosvagor/vagari.os.git && cd vagari.os && git pull origin hyprland && git checkout hyprland && generate-hardware-config && rebuild";
      spp = "rm -rf flake.lock && git stash; git pull; git stash pop";
      rebuild = "sudo nixos-rebuild switch --flake .#${hostname}";
    };

    enableCompletion = true;
    autosuggestion.enable = true;
    syntaxHighlighting.enable = true;

  };
}
