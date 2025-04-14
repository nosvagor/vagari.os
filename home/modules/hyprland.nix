{ pkgs, inputs, ... }: # Ensure inputs is available if needed
{
  home.packages = with pkgs; [
    firefox
    kitty
    ghostty
    alacritty
    xterm
    urxvt
  ];

  programs.kitty = {
    enable = true;
    settings = {
      backend = "software";
    };
  };


  wayland.windowManager.hyprland = {
    enable = true;

    settings = {
      "$mod" = "ALT"; 

      exec-once = [ "dbus-update-activation-environment --systemd --all" ];

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
        "$mod, f, exec, ghostty"
        "$mod, g, exec, firefox"
        "$mod, d, exec, alacritty"
        "$mod, t, exec, xterm"
        "$mod, u, exec, urxvt"
      ];
    };
  };
}
