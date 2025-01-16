# ██████╗██████╗ ███████╗ █████╗ ████████╗███████╗
# ██╔════╝██╔══██╗██╔════╝██╔══██╗╚══██╔══╝██╔════╝
# ██║     ██████╔╝█████╗  ███████║   ██║   █████╗  
# ██║     ██╔══██╗██╔══╝  ██╔══██║   ██║   ██╔══╝  
# ╚██████╗██║  ██║███████╗██║  ██║   ██║   ███████╗
#  ╚═════╝╚═╝  ╚═╝╚══════╝╚═╝  ╚═╝   ╚═╝   ╚══════╝
# Content creation and media production tools.
# Heavy-duty applications for video, 3D, and streaming.

{ pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    # Video Production
    obs-studio      # Streaming/recording
    handbrake       # Video transcoder
    ffmpeg-full     # Media tool suite
    blender         # 3D creation suite
    davinci-resolve # Video editing
    
    # Audio Production
    ardour          # Digital audio workstation
    audacity        # Audio editor
    
    # Image Processing
    darktable       # RAW processing
    rawtherapee     # RAW processing
    
    # Color Management
    displaycal      # Display calibration
    colord          # Color management
  ];
}
