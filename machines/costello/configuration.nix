# ██████╗ ██████╗ ███████╗████████╗███████╗██╗     ██╗      ██████╗ 
# ██╔════╝██╔═══██╗██╔════╝╚══██╔══╝██╔════╝██║     ██║     ██╔═══██╗
# ██║     ██║   ██║███████╗   ██║   █████╗  ██║     ██║     ██║   ██║
# ██║     ██║   ██║╚════██║   ██║   ██╔══╝  ██║     ██║     ██║   ██║
# ╚██████╗╚██████╔╝███████║   ██║   ███████╗███████╗███████╗╚██████╔╝
#  ╚═════╝ ╚═════╝ ╚══════╝   ╚═╝   ╚══════╝╚══════╝╚══════╝ ╚═════╝ 
# Main workstation configuration with full development environment.
# Includes gaming setup, content creation, and more powerful hardware configs.

{ config, pkgs, ... }:

{
  imports = [
    ./hardware-configuration.nix     # Generated hardware config
    ../shared/core.nix               # Shared core system settings
    ../shared/fonts.nix              # System-wide fonts
    ../shared/packages/base.nix      # Base packages
    ../shared/packages/build.nix     # Development tools
    ../shared/packages/create.nix    # Content creation
    ../shared/packages/game.nix      # Gaming packages
  ];

  # TODO: implement machine-specific configurations here
} 