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

  # Inputs are external dependencies that your configuration uses. -----------------------------------------------------
  inputs = { 

    # nixpkgs: The main source of packages and modules in Nix ecosystem 
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable"; # Using nixos-unstable for latest package versions
    
    # home-manager: Tool for managing user environment configuration in a modular fashion
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs"; # Prevents dependency conflicts by using the same nixpkgs as above
    }; 

  }; # -----------------------------------------------------------------------------------------------------------------

  # Outputs define what your flake provides to the system --------------------------------------------------------------
  outputs = { self, nixpkgs, home-manager, ... }: { 

    # NixOS machine configurations ---------------------------------------------
    nixosConfigurations = {
      "abbot" = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [ ./machines/abbot/configuration.nix ];
      };
      "costello" = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [ ./machines/costello/configuration.nix ];
      };
    }; # -----------------------------------------------------------------------

    # Home configurations for different machines/contexts ----------------------
    homeConfigurations = {
      "nosvagor-abbot" = home-manager.lib.homeManagerConfiguration {
        pkgs = nixpkgs.legacyPackages.x86_64-linux;
        modules = [ ./home/abbot.nix ];
      };
      "nosvagor-costello" = home-manager.lib.homeManagerConfiguration {
        pkgs = nixpkgs.legacyPackages.x86_64-linux;
        modules = [ ./home/costello.nix ];
      };
    }; # -----------------------------------------------------------------------

  }; # -----------------------------------------------------------------------------------------------------------------

} 