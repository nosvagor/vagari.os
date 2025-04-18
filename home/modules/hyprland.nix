{ pkgs, ... }:
{
  home.packages = with pkgs; [
    firefox-devedition-bin-unwrapped
    kitty
    dunst               # Notification daemon
    hyprpolkitagent     # Polkit agent for Hyprland
    hyprpicker          # Color picker
    hyprland-qt-support # Qt style for hypr* apps
    playerctl           # Media player controller
    grim                # Screenshot tool
    wl-clipboard        # Clipboard tool
    zathura             # PDF viewer
    wofi                # Application launcher
    wofi-emoji          # Emoji picker
  ];

  wayland.windowManager.hyprland = {
    enable = true;
    systemd.variables = ["--all"]; 

    settings = {
      "$mod"  = "SUPER";
      "$smod" = "SUPER_SHIFT";
      "$amod" = "SUPER_ALT";

      "$active" = "rgba(f2a170ee)";
      "$active_alt" = "rgba(e56b2c32)";
      "$inactive" = "rgba(7492efee)";
      "$inactive_alt" = "rgba(4a6be342)";


      # https://wiki.hyprland.org/Configuring/Monitors/
      monitor = [
      ];

      # https://wiki.hyprland.org/Configuring/Variables/#input
      input = {
        follow_mouse = 1; 
        sensitivity = 0; 
        repeat_rate = 42; 
        repeat_delay = 324; 
        float_switch_override_focus = 0; 
      };

      # https://wiki.hyprland.org/Configuring/Variables/#general
      general = {
        gaps_in = 13; 
        gaps_out = 0; 
        border_size = 3; 
        "col.active_border" = "$active"; 
        "col.inactive_border" = "$inactive";
        layout = "master"; 
        resize_on_border = false;
      };

      # See https://wiki.hyprland.org/Configuring/Variables/#decoration
      decoration = {
        rounding = 16; 
        active_opacity = 1.0; 
        inactive_opacity = 0.98; 
        fullscreen_opacity = 1.0; 

        blur = {
          enabled = true;
          size = 8;
          passes = 3;
        };

        shadows = true; 
        shadow_range = 40; 
        shadow_render_power = 4; 
        shadow_ignore_window = true; 
        "col.shadow" = "$active_alt"; 
        "col.shadow_inactive" = "$inactive_alt"; 
        shadow_offset = "0 0"; 
      };

      # See https://wiki.hyprland.org/Configuring/Animations/
      animations = {
        enabled = true;

        bezier = [
          "jerk, 1, -0.36, 0.72, 1.2"
          "snap, 0, 0.25, 0.5, 1.6"
        ];

        animation = [
          "windows, 1, 3, snap, popin"
          "windowsOut, 1, 4, default, popin 80%"
          "border, 1, 10, default"
          "fade, 1, 7, default"
          "workspaces, 1, 3, jerk, slide"
        ];
      };

      dwindle = {
        pseudotile = false;
        preserve_split = true;
        force_split = 2;
      };

      master = {};

      # https://wiki.hyprland.org/Configuring/Variables/#misc
      misc = {
      };

      # https://wiki.hyprland.org/Configuring/Binds/
      bind = [

        # --- Basic Commands ---
        "$mod, X, killactive,"
        "$smod, X, exec, hyprctl kill" 

        # --- Window Controls ---
        "$smod, T, togglefloating," 

        # --- Application Launching ---
        "$mod, Return, exec, kitty" 
        "$mod, F, exec, firefox-developer-edition" 
        "$smod, L, exec, lock" 
        "$smod, E, exec, microsoft-edge-dev" 
        "$smod, Z, exec, zathura" 
        "$mod, R, exec, wofi --show drun" 
        "$mod, PERIOD, exec, wofi-emoji" 
        "$smod CTRL, Y, exec, pkill guvcview"
        "$mod, Y, exec, pkill guvcview; guvcview & disown" # Launch guvcview

        # --- Move Focus (using your Alt + s/t/r/e layout) ---
        "ALT, S, movefocus, l"
        "ALT, T, movefocus, r"
        "ALT, R, movefocus, u"
        "ALT, E, movefocus, d"
        "ALT, G, cyclenext, prev"

        # --- Move Active Window ---
        "$amod, Left, movewindow, l"
        "$amod, Right, movewindow, r"
        "$amod, Up, movewindow, u"
        "$amod, Down, movewindow, d"

        # --- Workspace Switching ---
        "$mod, S, exec, hyprctl dispatch workspace 1"
        "$mod, E, exec, hyprctl dispatch workspace 2"
        "$mod, T, exec, hyprctl dispatch workspace 3"
        "$mod, D, exec, hyprctl dispatch workspace 4"
        "$mod, G, exec, hyprctl dispatch workspace 5"


        ", XF86AudioMute, exec, wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"
        ", XF86AudioMicMute, exec, wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle"
      ];

      # Media keys
      bindl = [
        ", XF86AudioPlay, exec, playerctl play-pause"
        ", XF86AudioNext, exec, playerctl next"
        ", XF86AudioPrev, exec, playerctl previous"
        ", XF86AudioStop, exec, playerctl stop"
      ];

      # Volume keys
      binde = [ 
        ", XF86AudioRaiseVolume, exec, wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%+"
        ", XF86AudioLowerVolume, exec, wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"
      ];

      # Mouse bindings
      bindm = [
        "$smod CTRL, mouse:272, movewindow"
        "$smod CTRL, mouse:273, resizewindow"
      ];

      # https://wiki.hyprland.org/Configuring/Window-Rules/
      windowrulev2 = [

      ];

      # https://wiki.hyprland.org/Configuring/Layer-Rules/
      layerrule = [
        "blur, notifications" 
        "ignorezero, notifications"
        "blur, rofi"        
      ];


      # https://wiki.hyprland.org/Plugins/Using-Plugins/
      plugin = {};

    }; 
  }; 

  # hyprland-qt-support config
  xdg.configFile."hypr/application-style.conf".text = ''
      roundness=1
      border_width=1
      reduce_motion=false
  '';

}
