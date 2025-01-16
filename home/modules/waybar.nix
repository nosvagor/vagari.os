{ config, pkgs, ... }:

{
  programs.waybar = {
    enable = true;
    style = ''
      * {
        font-family: "Iosevka Nerd Font";
        font-size: 13px;
        min-height: 0;
        border: none;
        border-radius: 0;
        margin: 0;
        padding: 0;
      }

      window#waybar {
        background: rgba(30, 30, 46, 0.95);
        color: #cdd6f4;
      }

      #workspaces button {
        padding: 0 5px;
        color: #cdd6f4;
      }

      #workspaces button.active {
        background: #cba6f7;
        color: #1e1e2e;
      }

      #clock,
      #battery,
      #cpu,
      #memory,
      #network,
      #pulseaudio,
      #tray {
        padding: 0 10px;
        margin: 0 5px;
        color: #cdd6f4;
      }
    '';
    settings = [{
      layer = "top";
      position = "top";
      modules-left = [ "hyprland/workspaces" ];
      modules-center = [ "clock" ];
      modules-right = [ "pulseaudio" "network" "cpu" "memory" "battery" "tray" ];
      
      "clock" = {
        format = "{:%H:%M}";
        format-alt = "{:%Y-%m-%d}";
        tooltip-format = "<tt><small>{calendar}</small></tt>";
      };
      
      "cpu" = {
        format = "CPU {usage}%";
        tooltip = false;
      };
      
      "memory" = {
        format = "RAM {}%";
      };
      
      "battery" = {
        states = {
          "good" = 95;
          "warning" = 30;
          "critical" = 15;
        };
        format = "{icon} {capacity}%";
        format-charging = " {capacity}%";
        format-plugged = " {capacity}%";
        format-icons = ["" "" "" "" ""];
      };
      
      "network" = {
        format-wifi = "直 {essid}";
        format-ethernet = " {ifname}";
        format-disconnected = "睊";
        tooltip-format = "{ifname} via {gwaddr}";
      };
      
      "pulseaudio" = {
        format = "{icon} {volume}%";
        format-muted = "婢";
        format-icons = {
          default = ["" "" ""];
        };
      };
    }];
  };
} 