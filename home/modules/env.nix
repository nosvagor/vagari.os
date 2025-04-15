{ pkgs, inputs, ... }: 
{
  home.sessionVariables = {
    TERMINAL = "kitty";
    EDITOR = "vim";
    BROWSER = "firefox";

    NIXOS_OZONE_WL = "1";
    WLR_NO_HARDWARE_CURSORS = "1"; 

    GDK_BACKEND = "wayland";
    SDL_VIDEODRIVER = "wayland";
    QT_QPA_PLATFORM = "wayland";
  };
}
