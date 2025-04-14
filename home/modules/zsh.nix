{ pkgs, hostname, ... }:
{
  programs.zsh = {
    enable = true;

    # Use the standard shellAliases option
    shellAliases = {
      clone = "git clone https://github.com/nosvagor/vagari.os.git && git pull origin hyprland && git checkout hyprland";
      spp = "git stash; git pull; git stash pop";
      rebuild = "sudo nixos-rebuild switch --flake .#${hostname}";
      ghcfg = "sudo nixos-generate-config --show-hardware-config > ./machines/${hostname}/hardware-configuration.nix && git add ./machines/${hostname}/hardware-configuration.nix && git commit -m 'Add hardware configuration for ${hostname}'";
    };

    plugins = [
      # Standard completion definitions
      { 
        name = "zsh-completions";
        src = pkgs.fetchFromGitHub {
          owner = "zsh-users";
          repo = "zsh-completions";
          rev = "0.35.0";
          sha256 = "sha256-GFHlZjIHUWwyeVoCpszgn4AmLPSSE8UVNfRmisnhkpg="; 
        };
      }
      # Fish-like autosuggestions
      {
        name = "zsh-autosuggestions";
        src = pkgs.fetchFromGitHub {
          owner = "zsh-users";
          repo = "zsh-autosuggestions";
          rev = "v0.7.1"; 
          sha256 = "sha256-vpTyYq9ZgfgdDsWzjxVAE7FZH4MALMNZIFyEOBLm5Qo="; 
        };
      }
      # Real-time type-ahead completion
       {
        name = "zsh-autocomplete";
        src = pkgs.fetchFromGitHub {
           owner = "marlonrichert";
           repo = "zsh-autocomplete";
           rev = "25.03.19"; 
           sha256 = "sha256-eb5a5WMQi8arZRZDt4aX1IV+ik6Iee3OxNMCiMnjIx4="; 
         };
       }
      # Syntax highlighting
      {
        name = "zsh-syntax-highlighting";
        src = pkgs.fetchFromGitHub {
          owner = "zsh-users";
          repo = "zsh-syntax-highlighting";
          rev = "0.8.0"; 
          sha256 = "sha256-iJdWopZwHpSyYl5/FQXEW7gl/SrKaYDEtTH9cGP7iPo="; 
        };
      }
    ];
  };
}
