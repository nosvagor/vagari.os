# ███████╗██████╗ ██████╗ ███╗   ███╗
# ██╔════╝██╔══██╗██╔══██╗████╗ ████║
# ███████╗██║  ██║██║  ██║██╔████╔██║
# ╚════██║██║  ██║██║  ██║██║╚██╔╝██║
# ███████║██████╔╝██████╔╝██║ ╚═╝ ██║
# ╚══════╝╚═════╝ ╚═════╝ ╚═╝     ╚═╝
# Display manager configuration using SDDM.
# Handles login screen and session management.

{ config, pkgs, ... }:

{
  services.xserver = {
    enable = true;               # Needed for SDDM
    displayManager.sddm = {
      enable = true;
      theme = "catppuccin";      # Using Catppuccin theme
      settings = {
        Theme = {
          CursorTheme = "Nordzy-cursors";
          Font = "Iosevka Vagari";
        };
      };
    };
  };

  # Install SDDM theme
  environment.systemPackages = with pkgs; [
    catppuccin-sddm-theme
  ];
} 