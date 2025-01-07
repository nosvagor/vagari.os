# ███╗   ███╗ █████╗ ██╗███╗   ██╗
# ████╗ ████║██╔══██╗██║████╗  ██║
# ██╔████╔██║███████║██║██╔██╗ ██║
# ██║╚██╔╝██║██╔══██║██║██║╚██╗██║
# ██║ ╚═╝ ██║██║  ██║██║██║ ╚████║
# ╚═╝     ╚═╝╚═╝  ╚═╝╚═╝╚═╝  ╚═══╝
# This is the entry point for your NixOS configuration.
# A flake is Nix's way of managing dependencies and making builds reproducible.

{
  # Simple description of your system. This is mostly for humans.
  description = "vagari.os - a personalized NixOS system";

  # Inputs are external dependencies that your configuration uses.
  inputs = {

    # nixpkgs: The main source of packages and modules in Nix ecosystem 
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable"; # Using nixos-unstable for latest package versions
    
    # home-manager: Tool for managing user environment configuration in a modular fashion
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs"; # Prevents dependency conflicts by using the same nixpkgs as above
    };

  };

  # Outputs define what your flake provides to the system
  outputs = { self, nixpkgs, home-manager, ... }: { # The parameters here are the inputs we defined above
                                     # the ... syntax means it accepts any other arguments

    # homeConfigurations: Different home-manager configurations for different use cases
    homeConfigurations = { # These can be activated using 'home-manager switch --flake .#<name>'

      # Default user configuration starting point; used to build other configurations
      "nosvagor-essentials" = home-manager.lib.homeManagerConfiguration {
        # TODO: Define default configuration
      };

      # Specialized configuration for gaming
      "nosvagor-game" = home-manager.lib.homeManagerConfiguration {
        # TODO: Define game-specific configuration
      };

      # Development environment focused on building software
      "nosvagor-build" = home-manager.lib.homeManagerConfiguration {
        # TODO: Define build-specific configuration
      };

      # Primary endgame configuration
      "nosvagor" = home-manager.lib.homeManagerConfiguration {
        # TODO: Define full-featured configuration
      };

    };


  };

} 