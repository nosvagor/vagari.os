{ pkgs, inputs, ... }: # Ensure inputs is available if needed
{
  home.packages = with pkgs; [
    kitty 
    firefox
    ];

  wayland.windowManager.hyprland = {
    enable = true;
    package = null; 
    portalPackage = null;

    systemd.variables = ["--all"]; 

    settings = {
      "$mod" = "SUPER"; 

      monitor=",preferred,auto,1";

      exec-once = [ ];

      input = {
        kb_layout = "us"; 
        follow_mouse = 1;
      };

      general = {
        gaps_in = 5;
        gaps_out = 10;
        border_size = 2;
      };
      
      bind = [
        "$mod, x, killactive,"
        "$mod, Return, exec, kitty"
        "$mod, F, exec, firefox"
      ];
    };
  };
}
