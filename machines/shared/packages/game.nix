# ██████╗  █████╗ ███╗   ███╗███████╗
# ██╔════╝ ██╔══██╗████╗ ████║██╔════╝
# ██║  ███╗███████║██╔████╔██║█████╗  
# ██║   ██║██╔══██║██║╚██╔╝██║██╔══╝  
# ╚██████╔╝██║  ██║██║ ╚═╝ ██║███████╗
#  ╚═════╝ ╚═╝  ╚═╝╚═╝     ╚═╝╚══════╝
# Gaming-related packages and tools.
# Includes game platforms, tools, and performance utilities.

{ pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    # Game Platforms
    steam           # Steam gaming platform
    lutris          # Game manager
    
    # Gaming Tools
    gamemode        # System optimization
    mangohud        # Performance overlay
    
    # Performance Tools
    corectrl        # AMD GPU control
    cpupower-gui    # CPU power management
  ];
}
