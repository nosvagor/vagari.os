{
  description = "Vagari.OS NixOS configuration - home manager initial setup";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, home-manager, ... }@inputs:
    let
      mkSystem = hostname: pkgsPlatform: {
        system = pkgsPlatform;
        specialArgs = { inherit inputs; inherit hostname; };
        modules = [
          inputs.home-manager.nixosModules.home-manager
          ({ config, pkgs, ... }: {
            home-manager = {
              useGlobalPkgs = true;
              useUserPackages = true;
              extraSpecialArgs = { inherit hostname; };
              users = {
                nosvagor = import ./home/nosvagor.nix;
                cullyn = import ./home/cullyn.nix;
              };
            };
          })
          ./machines/${hostname}/configuration.nix
        ];
      };
    in
    {
      nixosConfigurations = {
        abbot = mkSystem "abbot" "x86_64-linux";
      };
    };
} 