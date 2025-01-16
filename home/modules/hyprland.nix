{ config, pkgs, ... }:

{
  wayland.windowManager.hyprland = {
    enable = true;
    settings = {
      general = {
        gaps_in = 5;
        gaps_out = 10;
        border_size = 2;
        "col.active_border" = "rgba(5e81acee)";
        "col.inactive_border" = "rgba(4c566aaa)";
        layout = "dwindle";
      };

      decoration = {
        rounding = 10;
        blur = {
          enabled = true;
          size = 3;
          passes = 1;
          new_optimizations = true;
        };
        drop_shadow = true;
        shadow_range = 4;
        shadow_render_power = 3;
      };

      animations = {
        enabled = true;
        bezier = "myBezier, 0.05, 0.9, 0.1, 1.05";
        animation = [
          "windows, 1, 7, myBezier"
          "windowsOut, 1, 7, default, popin 80%"
          "border, 1, 10, default"
          "fade, 1, 7, default"
          "workspaces, 1, 6, default"
        ];
      };

      dwindle = {
        pseudotile = true;
        preserve_split = true;
      };

      misc = {
        force_default_wallpaper = 0;
      };

      workspace = [
        "1, code,  "
        "2, web,   "
        "3, term,  "
        "4, files, "
        "5, media, "
      ];
    };

    extraConfig = ''
      # Environment Variables
      env = XCURSOR_SIZE,24
      env = GTK_THEME,Nordic
      env = QT_QPA_PLATFORMTHEME,qt5ct

      # Core bindings
      bind = SUPER, Return, exec, wezterm
      bind = SUPER, Q, killactive,
      bind = SUPER SHIFT, Q, exit,
      bind = SUPER, V, togglefloating,
      bind = SUPER, Space, exec, wofi --show drun
      bind = SUPER, P, pseudo,
      bind = SUPER, F, fullscreen,
      bind = SUPER, J, togglesplit,

      # Custom workspace movement (SEDT layout)
      $move_workspace = hyprctl dispatch workspace
      bind = SUPER, s, exec, $move_workspace 1
      bind = SUPER, e, exec, $move_workspace 2
      bind = SUPER, t, exec, $move_workspace 3
      bind = SUPER, d, exec, $move_workspace 4
      bind = SUPER, g, exec, $move_workspace 5

      # Move windows to workspaces
      bind = SUPER SHIFT, s, movetoworkspace, 1
      bind = SUPER SHIFT, e, movetoworkspace, 2
      bind = SUPER SHIFT, t, movetoworkspace, 3
      bind = SUPER SHIFT, d, movetoworkspace, 4
      bind = SUPER SHIFT, g, movetoworkspace, 5

      # Mouse bindings
      bindm = SUPER, mouse:272, movewindow
      bindm = SUPER, mouse:273, resizewindow

      # Screenshot bindings
      bind = , Print, exec, grim -g "$(slurp)" - | wl-copy
      bind = SHIFT, Print, exec, grim -g "$(slurp)" ~/Pictures/Screenshots/$(date +'%Y%m%d_%H%M%S').png
      bind = SUPER, Print, exec, grim - | wl-copy
      
      # Media keys
      bind = , XF86AudioRaiseVolume, exec, wpctl set-volume -l 1.0 @DEFAULT_AUDIO_SINK@ 5%+
      bind = , XF86AudioLowerVolume, exec, wpctl set-volume -l 1.0 @DEFAULT_AUDIO_SINK@ 5%-
      bind = , XF86AudioMute, exec, wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle

      # Startup
      exec-once = waybar
      exec-once = wl-paste --type text --watch cliphist store
      exec-once = wl-paste --type image --watch cliphist store
      exec-once = hyprpaper
      exec-once = dunst
      
      # Window rules
      windowrule = workspace 2, firefox-devedition
      windowrule = workspace 2, firefox
      windowrule = workspace 2, chromium
      windowrule = workspace 2, brave
      windowrule = workspace 2, microsoft-edge
      windowrule = workspace 4, pcmanfm
      windowrule = float, pavucontrol
      windowrule = float, file_progress
      windowrule = float, confirm
      windowrule = float, dialog
      windowrule = float, download
      windowrule = float, notification
      windowrule = float, error
      windowrule = float, splash
      windowrule = float, confirmreset
      windowrule = float, title:Open File
      windowrule = float, title:branchdialog
      windowrule = float, zoom
      windowrule = float, vlc
      
      # Layer rules
      layerrule = blur, waybar
      layerrule = blur, wofi
    '';
  };

  home.packages = with pkgs; [
    dunst
    cliphist
    wl-clipboard
    hyprpaper
    grim
    slurp
    wpctl
    pavucontrol
  ];

  home.file.".local/share/screenshots/.keep".text = "";
} 