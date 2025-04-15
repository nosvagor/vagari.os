{ pkgs, inputs, ... }: 
{
  xdg.portal = {
    enable = true; 
    config.common.default = "*"; 
  };

  services.displayManager.sddm = {
    enable = true;
    wayland.enable = true; 
  };

  programs.hyprland = {
    enable = true;
    package = inputs.hyprland.packages.${pkgs.system}.hyprland;
    portalPackage = inputs.hyprland.packages.${pkgs.system}.xdg-desktop-portal-hyprland;
    xwayland.enable = true;
  };

  hardware.graphics.enable = true;
}
