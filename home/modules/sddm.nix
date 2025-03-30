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
   environment.systemPackages = with pkgs; [
    catppuccin-sddm-theme
  ];

  services.xserver = {
    enable = true;               
    displayManager.sddm = {
      enable = true;
      theme = "catppuccin";      
      settings = {
        Theme = {
          CursorTheme = "Nordzy-cursors";
          Font = "Iosevka Vagari";
        };
      };
    };
  };

 
} 