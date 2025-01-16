# ███████╗ ██████╗ ███╗   ██╗████████╗███████╗
# ██╔════╝██╔═══██╗████╗  ██║╚══██╔══╝██╔════╝
# █████╗  ██║   ██║██╔██╗ ██║   ██║   ███████╗
# ██╔══╝  ██║   ██║██║╚██╗██║   ██║   ╚════██║
# ██║     ╚██████╔╝██║ ╚████║   ██║   ███████║
# ╚═╝      ╚═════╝ ╚═╝  ╚═══╝   ╚═╝   ╚══════╝
# System-wide font configuration and rendering settings.

{ config, pkgs, ... }:

{
  fonts = {
    packages = with pkgs; [
      # Core UI Fonts
      satoshi             # Variable geometric sans-serif (primary UI)
      outfit              # Variable geometric display

      # Monospace
      (pkgs.iosevka.override { # https://typeof.net/Iosevka/customizer
        privateBuildPlan = {
          family = "Iosevka Vagari";
          spacing = "normal";
          serifs = "sans";
          noCvSs = true;
          exportGlyphNames = false;

          # Character Variants
          variants.design = {
            one = "no-base-flat-top-serif";
            two = "curly-neck-serifed";
            three = "flat-top-serifed";
            four = "semi-open-non-crossing-serifless";
            five = "upright-arched-serifed";
            six = "straight-bar";
            seven = "straight-serifed";
            eight = "crossing";
            nine = "straight-bar";
            zero = "tall-slashed-cutout";
            capital-a = "straight-serifless";
            h = "straight-serifless";
            i = "serifless";
            j = "flat-hook-serifless";
            k = "straight-serifless";
            l = "flat-tailed";
            m = "short-leg-serifless";
            n = "straight-serifless";
            p = "eared-serifless";
            r = "serifless";
            t = "flat-hook";
            u = "toothed-serifless";
            v = "straight-serifless";
          };

          # Ligature Sets
          ligations = {
            inherits = "purescript";
          };
        };
        set = "vagari";  # Changed from "custom" to match your family name
      })
      
      # Text & Reading
      eb-garamond         # Classic serif
      crimson             # Modern serif
      
      # Symbols & Emoji
      symbols-nerd-font   # Development icons (symbols only)
      noto-fonts-emoji    # Color emoji support
      
      # Math & Science
      stix-two            # Professional math symbols
      
      # Extended Language Support
      noto-fonts          # Base Unicode coverage
      noto-fonts-cjk      # chinese, japanese, korean
      noto-fonts-extra    # Extended scripts
      hanazono            # Rare CJK characters
      amiri               # Arabic
      lohit-fonts         # Indic scripts
      culmus              # Hebrew
      
      # Essential Fallbacks
      dejavu_fonts        # Comprehensive coverage
      liberation_ttf      # Metric-compatible with MS fonts
      
      # Stylistic & Handwritten
      caveat              # Casual handwritten, very readable
      dancing-script      # Elegant cursive
      petit-formal-script # Formal handwritten
      kalam               # Natural handwriting style
      permanent-marker    # Bold marker style
      pacifico            # Friendly script
      indie-flower        # Casual handwritten
    ];

    # System-wide font defaults
    fontconfig = {
      defaultFonts = {
        serif = [ "Crimson" "EB Garamond" "DejaVu Serif" ];
        sansSerif = [ "Satoshi" "Inter" "DejaVu Sans" ];
        monospace = [ "Iosevka" "DejaVu Sans Mono" ];
        emoji = [ "Noto Color Emoji" ];
      };
      
      # Modern rendering settings
      subpixel = {
        rgba = "rgb";
        lcdfilter = "default";
      };

      hinting = {
        enable = true;
        style = "slight";
      };

      antialias = true;
    };

    fontDir.enable = true;
    enableDefaultPackages = false;
  };
} 