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
    let
      # Helper function to build a NixOS system configuration
      mkSystem = hostname: system:
        let
          pkgs = nixpkgs.legacyPackages.${system};
          primaryUser = "nosvagor";
        in
        nixpkgs.lib.nixosSystem {
          inherit system;
          specialArgs = { inherit inputs pkgs hostname primaryUser; };
          modules = [
            ./machines/${hostname}/configuration.nix
            home-manager.nixosModules.home-manager
            {
              home-manager.useGlobalPkgs = true;
              home-manager.useUserPackages = true;
              home-manager.users.${primaryUser} = import ./home/${hostname}.nix;
              home-manager.extraSpecialArgs = { inherit inputs hostname primaryUser; };
            }

            sops-nix.nixosModules.sops
          ];
        };
    in
    {
      nixosConfigurations = {
        abbot = mkSystem "abbot" "x86_64-linux";
        # costello = mkSystem "costello" "x86_64-linux"; # Uncomment or add others
      };
    };
  # ----------------------------------------------------------------------------
} 