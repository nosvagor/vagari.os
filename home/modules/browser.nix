{ config, pkgs, ... }:

{
  programs.firefox = {
    enable = true;
    package = pkgs.firefox-devedition;  # Use Firefox Developer Edition

    profiles = {
      default = {
        id = 0;
        name = "default";
        isDefault = true;
        settings = {
          # HiDPI settings
          "layout.css.devPixelsPerPx" = "1.25";

          # Session management
          "browser.sessionstore.resume_from_crash" = false;

          # PDF viewer settings
          "pdfjs.sidebarViewOnLoad" = 0;

          # Disable Pocket
          "extensions.pocket.enabled" = false;

          # Privacy enhancements
          "privacy.trackingprotection.enabled" = true;
          "browser.send_pings" = false;
          "browser.urlbar.speculativeConnect.enabled" = false;
          "dom.security.https_only_mode" = true;
          "dom.security.https_only_mode_ever_enabled" = true;
          "geo.enabled" = false;
          
          # Performance settings
          "gfx.webrender.all" = true;
          "media.ffmpeg.vaapi.enabled" = true;
          "media.hardware-video-decoding.force-enabled" = true;

          # UI settings
          "browser.toolbars.bookmarks.visibility" = "never";
          "browser.newtabpage.enabled" = false;
          "browser.startup.homepage" = "about:blank";
          
          # Developer settings
          "devtools.theme" = "dark";
          "devtools.toolbox.host" = "right";
          "devtools.chrome.enabled" = true;
          "devtools.debugger.remote-enabled" = true;
        };

        # UserChrome customization
        userChrome = ''
          /* Hide tab bar if only one tab open */
          #tabbrowser-tabs {
            visibility: collapse !important;
          }
          
          #tabbrowser-tabs[singletononly="true"] {
            visibility: collapse !important;
          }

          /* Hide sidebar header */
          #sidebar-header {
            display: none !important;
          }

          /* Compact UI */
          :root {
            --tab-min-height: 24px !important;
            --newtab-textbox-background-color: var(--toolbar-field-background-color) !important;
          }

          /* Match Nordic theme colors */
          :root {
            --toolbar-bgcolor: #2E3440 !important;
            --toolbar-bgimage: none !important;
            --toolbar-color: #D8DEE9 !important;
            --toolbar-field-background-color: #3B4252 !important;
            --toolbar-field-color: #E5E9F0 !important;
          }
        '';

        # Enable userChrome.css
        extraConfig = ''
          user_pref("toolkit.legacyUserProfileCustomizations.stylesheets", true);
        '';
      };

      # Additional profile for testing
      testing = {
        id = 1;
        name = "testing";
        settings = {
          "layout.css.devPixelsPerPx" = "1.25";
          "browser.sessionstore.resume_from_crash" = false;
        };
      };
    };
  };

  # Install additional browsers for testing
  home.packages = with pkgs; [
    # Browsers
    firefox            # Regular Firefox
    firefox-devedition   # Firefox Developer Edition
    google-chrome       # Chrome
    microsoft-edge      # Edge
    brave              # Brave Browser

    # Browser development tools
    chromedriver       # For automated testing
    geckodriver        # Firefox WebDriver
  ];

  # Create desktop entries to distinguish between browsers
  xdg.desktopEntries = {
    firefox-dev = {
      name = "Firefox Developer";
      genericName = "Web Browser";
      exec = "firefox-devedition %U";
      icon = "firefox-developer-edition";
      categories = [ "Network" "WebBrowser" ];
      mimeType = [ "text/html" "text/xml" ];
    };

    firefox-testing = {
      name = "Firefox Testing";
      genericName = "Web Browser";
      exec = "firefox -P testing %U";
      icon = "firefox";
      categories = [ "Network" "WebBrowser" ];
    };
  };
} 