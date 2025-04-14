{ pkgs, inputs, ... }: 
{
  xdg.portal = {
    enable = true; 
    extraPortals = [ ]; 
    config.common.default = "*"; 
  };

  services.displayManager.sddm = {
    enable = true;
    wayland.enable = true; 
  };

  environment.sessionVariables = {
    NIXOS_OZONE_WL = "1"; 
    WLR_NO_HARDWARE_CURSORS = "1"; 
  };

  programs.hyprland = {
    enable = true;
    package = inputs.hyprland.packages.${pkgs.system}.hyprland;
    portalPackage = inputs.hyprland.packages.${pkgs.system}.xdg-desktop-portal-hyprland;
    xwayland.enable = true;
  };

  hardware.graphics.enable = true;
}
