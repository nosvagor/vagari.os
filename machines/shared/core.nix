# ██████╗ ██████╗ ██████╗ ███████╗
# ██╔════╝██╔═══██╗██╔══██╗██╔════╝
# ██║     ██║   ██║██████╔╝█████╗  
# ██║     ██║   ██║██╔══██╗██╔══╝  
# ╚██████╗╚██████╔╝██║  ██║███████╗
#  ╚═════╝ ╚═════╝ ╚═╝  ╚═╝╚══════╝
# Core system configuration shared across all machines.
# Override these in machine-specific configurations as needed.

{ config, pkgs, ... }:

{
  # Boot configuration: systemd-boot with EFI support --------------------------
  boot = {
    loader = {
      systemd-boot.enable = true;      # systemd-boot with EFI support
      efi.canTouchEfiVariables = true; # allow systemd-boot to modify EFI variables
      
      # Optional but useful systemd-boot settings
      systemd-boot = {
        configurationLimit = 10;  # Keep only last 10 generations
        consoleMode = "max";      # Larger boot menu text
        editor = false;           # Disable kernel param editing for security
      };
    };
    
    # Kernel parameters for a cleaner boot experience
    kernelParams = [ 
      "quiet"      # Reduce boot messages
      "splash"     # Show splash screen
      "loglevel=3" # Further reduce boot verbosity
    ];
    
    # Pure btrfs setup for snapshots and CoW features
    supportedFilesystems = [ "btrfs" ];
    btrfs = {
      autoScrub = {
        enable = true;
        interval = "weekly";
      };
    };
  }; # -------------------------------------------------------------------------

  # Hardware support and firmware settings -------------------------------------
  hardware = {
    enableAllFirmware = true;        # enable all firmware
    cpu.amd.updateMicrocode = true;  # Change to intel.updateMicrocode for Intel
    
    # Modern audio stack using Pipewire
    pulseaudio.enable = false;  # Disable PulseAudio daemon completely
    
    # Graphics support with 32-bit compatibility
    opengl = {
      enable = true;
      driSupport = true;
      driSupport32Bit = true;
    };
  }; # -------------------------------------------------------------------------

  # Essential system services --------------------------------------------------
  services = {
    # Hardware health and maintenance
    thermald.enable = true; 
    fstrim.enable = true;  # Periodic SSD trimming
    
    # Modern audio system with compatibility layers
    pipewire = {
      enable = true;
      alsa.enable = true;          # ALSA support
      alsa.support32Bit = true;    # 32-bit ALSA support
      pulse.enable = true;         # PulseAudio protocol support (not the daemon)
      jack.enable = true;          # JACK protocol support
    };
  }; # -------------------------------------------------------------------------

  # User accounts configuration ------------------------------------------------
  users.users = {
    nosvagor = {
      isNormalUser = true;
      extraGroups = [ 
        "wheel"           # Admin/sudo privileges (core system group)
        "networkmanager"  # Network settings without sudo (core system group)
        "video"           # Access to video devices, needed for Wayland (core system group)
        "audio"           # Direct audio device access if needed (core system group)
        "docker"          # Optional: Run docker commands without sudo
        "libvirtd"        # Optional: VM/QEMU management
        "input"           # Optional: Access input devices directly
        "wireshark"       # Optional: Capture packets without sudo
      ];
      shell = pkgs.nushell;
      initialPassword = "changeme";
    }; # -----------------------------------------------------------------------

    root.shell = pkgs.nushell;
  };

  # Basic security services ----------------------------------------------------
  security = {
    rtkit.enable = true;    # Real-time process priority (pipewire/audio)
    polkit.enable = true;   # Access control (system tasks)

    # PAM: Authentication modules
    pam.services = {
      login.enableGnomeKeyring = true;  # Unlock keyring on login
    };

    # Sudo configuration
    sudo = {
      enable = true;
      wheelNeedsPassword = true;  # Require password for sudo
      extraRules = [{
        users = [ "nosvagor" ];
        commands = [
          { command = "ALL"; options = [ "NOPASSWD" ]; }
        ];
      }];
    };

  }; # -------------------------------------------------------------------------

  # Firewall settings --------------------------------------------------------
  networking.firewall = {
    enable = true;              # Best practice: Always enable firewall
    allowPing = false;          # Disable ICMP ping (optional security)
    allowedTCPPortRanges = [];  # No open TCP port ranges
    allowedUDPPortRanges = [];  # No open UDP port ranges
  }; # -------------------------------------------------------------------------

  fileSystems = {
    "/" = {
      device = "/dev/mapper/root";
      fsType = "btrfs";
      options = [ "subvol=@" "compress=zstd" "noatime" ];
    };
    "/home" = {
      device = "/dev/mapper/root";
      fsType = "btrfs";
      options = [ "subvol=@home" "compress=zstd" "noatime" ];
    };
    "/nix" = {
      device = "/dev/mapper/root";
      fsType = "btrfs";
      options = [ "subvol=@nix" "compress=zstd" "noatime" ];
    };
    "/.snapshots" = {
      device = "/dev/mapper/root";
      fsType = "btrfs";
      options = [ "subvol=@snapshots" "compress=zstd" "noatime" ];
    };
  };

  swapDevices = [{
    device = "/.swap/swapfile";
    size = 4096;  # 4GB in MB
  }];

  # Create swapfile in BTRFS subvolume
  systemd.services.create-swap = {
    serviceConfig.Type = "oneshot";
    wantedBy = [ "swap-swapfile.swap" ];
    script = ''
      mkdir -p /.swap
      truncate -s 0 /.swap/swapfile
      chattr +C /.swap/swapfile
      btrfs property set /.swap/swapfile compression none
      dd if=/dev/zero of=/.swap/swapfile bs=1M count=4096
      chmod 600 /.swap/swapfile
      mkswap /.swap/swapfile
    '';
  };
} 