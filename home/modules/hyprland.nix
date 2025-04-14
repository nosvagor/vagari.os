{ pkgs, inputs, ... }: # Ensure inputs is available if needed
{
  home.packages = with pkgs; [
    firefox
  ];

  wayland.windowManager.hyprland = {
    enable = true;

    settings = {
      "$mod" = "SUPER"; 

      input = {
        kb_layout = "us"; 
        follow_mouse = 1;
      };

      debug = {
        disable_logs = false;
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
