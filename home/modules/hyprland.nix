{ pkgs, ... }: 
{
  home.packages = with pkgs; [
    firefox
    kitty
  ];

  wayland.windowManager.hyprland = {
    enable = true;
    package = null;
    portalPackage = null;

    settings = {
      "$mod" = "SUPER_SHIFT"; 

      bind = [
        "$mod, X, killactive,"
        "$mod, Return, exec, kitty"
        "$mod, F, exec, firefox"
        "$mod, P, exec, cursor"
      ];
    };
  };
}
