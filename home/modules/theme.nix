# theme 


{ config, pkgs, ... }:

{
  # Theme configuration
  home.packages = with pkgs; [
    # Themes
    nordic              # GTK theme
    libsForQt5.nordic   # Qt/KDE theme
    libsForQt5.nordic-kde # Additional KDE components
    nordzy-cursor-theme # Cursor theme
    nordzy-icon-theme   # Icon theme
    
    # Theme configuration tools
    qt5ct
    qt6ct
    
    # Additional theming utilities
    libsForQt5.qtstyleplugin-kvantum  # Advanced Qt theming
    libsForQt5.qt5ct                  # Qt5 configuration tool
  ];

  # GTK Configuration
  gtk = {
    enable = true;
    theme = {
      name = "Nordic";
      package = pkgs.nordic;
    };
    iconTheme = {
      name = "Nordzy";
      package = pkgs.nordzy-icon-theme;
    };
    gtk3.extraConfig = {
      gtk-application-prefer-dark-theme = true;
    };
    gtk4.extraConfig = {
      gtk-application-prefer-dark-theme = true;
    };
  };

  # Qt Configuration
  qt = {
    enable = true;
    platformTheme = "qtct";
    style = {
      name = "Nordic";
      package = pkgs.libsForQt5.nordic;
    };
  };

  # Cursor Configuration
  home.pointerCursor = {
    name = "Nordzy-white";
    package = pkgs.nordzy-cursor-theme;
    size = 24;
    x11.enable = true;
    gtk.enable = true;
  };

  # Environment variables for theming
  home.sessionVariables = {
    # Qt theme configuration
    QT_QPA_PLATFORMTHEME = "qtct";
    QT_AUTO_SCREEN_SCALE_FACTOR = "1";
    QT_STYLE_OVERRIDE = "Nordic";
    
    # GTK theme configuration
    GTK_THEME = "Nordic";
    
    # Icon theme
    XCURSOR_THEME = "Nordzy-white";
    XCURSOR_SIZE = "24";
  };

  # Theme-related XDG configurations
  xdg.configFile = {
    # Qt5ct configuration
    "qt5ct/qt5ct.conf".text = ''
      [Appearance]
      custom_palette=false
      icon_theme=Nordzy
      standard_dialogs=default
      style=Nordic

      [Fonts]
      fixed="Iosevka Nerd Font,12,-1,5,50,0,0,0,0,0"
      general="Iosevka Nerd Font,12,-1,5,50,0,0,0,0,0"
    '';

    # Kvantum configuration
    "Kvantum/kvantum.kvconfig".text = ''
      [General]
      theme=Nordic
    '';

    # GTK-3.0 settings
    "gtk-3.0/settings.ini".text = ''
      [Settings]
      gtk-application-prefer-dark-theme=1
      gtk-theme-name=Nordic
      gtk-icon-theme-name=Nordzy
      gtk-font-name=Iosevka Nerd Font 12
      gtk-cursor-theme-name=Nordzy-white
      gtk-cursor-theme-size=24
      gtk-toolbar-style=GTK_TOOLBAR_BOTH_HORIZ
      gtk-toolbar-icon-size=GTK_ICON_SIZE_LARGE_TOOLBAR
      gtk-button-images=1
      gtk-menu-images=1
      gtk-enable-event-sounds=0
      gtk-enable-input-feedback-sounds=0
      gtk-xft-antialias=1
      gtk-xft-hinting=1
      gtk-xft-hintstyle=hintslight
      gtk-xft-rgba=rgb
    '';

    # GTK-4.0 settings
    "gtk-4.0/settings.ini".text = ''
      [Settings]
      gtk-application-prefer-dark-theme=1
      gtk-theme-name=Nordic
      gtk-icon-theme-name=Nordzy
      gtk-font-name=Iosevka Nerd Font 12
      gtk-cursor-theme-name=Nordzy-white
      gtk-cursor-theme-size=24
    '';
  };

  # Additional theme-related systemd services
  systemd.user.services = {
    gtk-theme-init = {
      Unit = {
        Description = "Initialize GTK theme settings";
        After = [ "graphical-session-pre.target" ];
        PartOf = [ "graphical-session.target" ];
      };
      Install = {
        WantedBy = [ "graphical-session.target" ];
      };
      Service = {
        Type = "oneshot";
        RemainAfterExit = true;
        ExecStart = "${pkgs.bash}/bin/bash -c 'gsettings set org.gnome.desktop.interface gtk-theme Nordic'";
      };
    };
  };
} 