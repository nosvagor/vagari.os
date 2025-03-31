# ███╗   ███╗ █████╗ ██╗███╗   ██╗
# ████╗ ████║██╔══██╗██║████╗  ██║
# ██╔████╔██║███████║██║██╔██╗ ██║
# ██║╚██╔╝██║██╔══██║██║██║╚██╗██║
# ██║ ╚═╝ ██║██║  ██║██║██║ ╚████║
# ╚═╝     ╚═╝╚═╝  ╚═╝╚═╝╚═╝  ╚═══╝
# This is the entry point for your NixOS configuration.
# A flake is Nix's way of managing dependencies and making builds reproducible.

{
  description = "vagari.os - a personalized NixOS system";

  # ╦╔╗╔╔═╗╦ ╦╔╦╗╔═╗
  # ║║║║╠═╝║ ║ ║ ╚═╗                            latest | home-manager | sops-nix
  # ╩╝╚╝╩  ╚═╝ ╩ ╚═╝ -----------------------------------------------------------
  inputs = { 
    # nixpkgs: latest nixpkgs
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

    # home-manager: app config manager
    home-manager = {
      url = "github:nix-community/home-manager";         
      inputs.nixpkgs.follows = "nixpkgs"; 
    }; 

    # sops-nix: secrets manager
    sops-nix = {
      url = "github:Mic92/sops-nix";                     
      inputs.nixpkgs.follows = "nixpkgs"; 
    };
  };
  # ----------------------------------------------------------------------------


  # ╔═╗╦ ╦╔╦╗╔═╗╦ ╦╔╦╗╔═╗
  # ║ ║║ ║ ║ ╠═╝║ ║ ║ ╚═╗                                       abbot | costello
  # ╚═╝╚═╝ ╩ ╩  ╚═╝ ╩ ╚═╝ ------------------------------------------------------
  outputs = { self, nixpkgs, home-manager, sops-nix, ... }@inputs:

    # mkSystem {machine} -> system config
    let
      system = "x86_64-linux";
      primaryUser = "nosvagor"; 
      mkSystem = machineName: nixpkgs.lib.nixosSystem {
        inherit system;
        specialArgs = { 
          inherit inputs primaryUser machineName; 
        };
        modules = [
          ./machines/${machineName}/configuration.nix
          home-manager.nixosModules.home-manager {
            home-manager = {
              useGlobalPkgs = true;
              useUserPackages = true;
              users.${primaryUser} = import ./home/${machineName}.nix;
              extraSpecialArgs = { inherit inputs primaryUser machineName; };
            };
          }
          sops-nix.nixosModules.sops
        ];
      };
    in 

    # extend by adding: ./machines/{machine}/configuration.nix
    #                   ./home/{machine}.nix
    { 
      nixosConfigurations = {
        "abbot" = mkSystem "abbot";
        "costello" = mkSystem "costello";
      };
    };
  # ----------------------------------------------------------------------------
} 