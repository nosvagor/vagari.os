# ██████╗  █████╗ ███████╗███████╗
# ██╔══██╗██╔══██╗██╔════╝██╔════╝
# ██████╔╝███████║███████╗█████╗  
# ██╔══██╗██╔══██║╚════██║██╔══╝  
# ██████╔╝██║  ██║███████║███████╗
# ╚═════╝ ╚═╝  ╚═╝╚══════╝╚══════╝
# Base packages needed across all configurations.
# Modern alternatives to traditional tools, focusing on speed and features.

{ pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    # Core Replacements (best-in-class)
    eza            # Modern ls
    bat            # Modern cat
    fd             # Modern find
    ripgrep        # Modern grep
    du-dust        # Modern du
    btop           # Modern system monitor
    procs          # Modern ps
    zoxide         # Modern cd
    
    # Network Tools
    age            # Modern encryption (replaces gpg for simple needs)
    dogdns         # Modern dig (DNS lookup)
    mtr            # Modern traceroute
    iperf3         # Network performance
    nmap           # Network discovery
    socat          # Socket tool (modern netcat)
    ipcalc         # IP calculator
    
    # System Tools
    lm_sensors     # Hardware monitoring
    nvtop          # GPU process monitor
    powertop       # Power consumption
    sysstat        # System statistics
    ethtool        # Network driver info
    pciutils       # PCI utilities (lspci)
    usbutils       # USB utilities (lsusb)
    
    # Core Dev Tools
    git            # Version control
    jq             # JSON processor
    yq             # YAML processor

    # Common Applications
    discord        # Chat & communities
    spotify        # Music streaming
    zoom-us        # Video conferencing
    zathura        # PDF viewer
    mpv            # Media player
    imv            # Image viewer
    peek           # GIF recorder
    wf-recorder    # Wayland recorder
    
    # Basic Creation Tools
    gimp           # Image editor
    inkscape       # Vector graphics
    ffmpeg         # Media tool suite

  ];
}
