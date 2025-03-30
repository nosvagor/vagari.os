#  ██████╗ ██████╗ ██████╗ ███████╗
# ██╔════╝██╔═══██╗██╔══██╗██╔════╝
# ██║     ██║   ██║██████╔╝█████╗  
# ██║     ██║   ██║██╔══██╗██╔══╝  
# ╚██████╗╚██████╔╝██║  ██║███████╗
#  ╚═════╝ ╚═════╝ ╚═╝  ╚═╝╚══════╝
# Core system configuration (boot, users, security, hardware/services, networking, filesystems/swap, nix)

{ config, pkgs, primaryUser, machineName, sops-nix, ... }:

{
  # ╔╗ ╔═╗╔═╗╔╦╗
  # ╠╩╗║ ║║ ║ ║                                                             BOOT
  # ╚═╝╚═╝╚═╝ ╩ ----------------------------------------------------------------
  environment.systemPackages = with pkgs; [ plymouth ];
  boot = {
    loader = {
      systemd-boot = {
        enable = true;                 # Use systemd-boot for UEFI booting
        configurationLimit = 10;       # Keep last 10 generations
        consoleMode = "max";           # Use resolution for boot menu
      };
      efi.canTouchEfiVariables = true; # For systemd-boot to manage entries
    };
    
    plymouth = {
      enable = true;         # Enable Plymouth service for graphical boot animation
      theme = "bgrt";        # Use UEFI vendor logo theme (custom theme can be made)
    };

    kernelParams = [
      "quiet"                # Reduce kernel messages during boot
      "splash"               # Enable graphical boot splash (requires plymouth service)
      "loglevel=4"           # Kernel log level (4 = warnings and errors)
      "slab_nomerge"         # Prevents merging kernel slabs of similar sizes, making heap overflows harder
      "init_on_alloc=1"      # Zeros memory pages on allocation, mitigating some info leaks & use-after-free bugs
      "init_on_free=1"       # Zeros memory pages on free, also mitigating use-after-free bugs
      "page_alloc.shuffle=1" # Randomizes page allocator freelists, making heap exploitation harder
      "vsyscall=none"        # Disables legacy vsyscall mechanism (potential security risk, replaced by vDSO)
      "debugfs=off"          # Disables the kernel debug filesystem (reduces attack surface)
    ];

    blacklistedKernelModules = [ "pcspkr" ];
    kernel.sysctl = {
      "kernel.kptr_restrict" = "1";         # Restrict exposing kernel pointers via /proc
      "kernel.dmesg_restrict" = "1";        # Restrict unprivileged users from reading kernel logs via dmesg
      "kernel.sched_autogroup_enabled" = 1; # Improve desktop interactivity by preventing background tasks hogging CPU
      "vm.swappiness" = 10;                 # Reduce swap usage frequency on systems with enough RAM
    };
  };
  # -------------------------------------------------------------------------

  # ╦ ╦╔═╗╔═╗╦═╗  
  # ║ ║╚═╗║╣ ╠╦╝                                                           USERS
  # ╚═╝╚═╝╚═╝╩╚═ ---------------------------------------------------------------
  environment.shells = [ pkgs.zsh ];
  users.users = {
    ${primaryUser} = {
      isNormalUser = true; 
      description = "Primary user for ${machineName}";
      extraGroups = [ "networkmanager" "video" "audio" ];
      shell = pkgs.zsh;    
    };
    root.shell = pkgs.zsh; 
  };
  time.timeZone = "America/Los_Angeles";
  i18n.defaultLocale = "en_US.UTF-8";
  i18n.extraLocaleSettings ={
    LC_ADDRESS = "en_US.UTF-8"; 
    LC_IDENTIFICATION = "en_US.UTF-8";
    LC_MEASUREMENT = "en_US.UTF-8";
    LC_MONETARY = "en_US.UTF-8";
    LC_NAME = "en_US.UTF-8";
    LC_NUMERIC = "en_US.UTF-8";
    LC_PAPER = "en_US.UTF-8";
    LC_TELEPHONE = "en_US.UTF-8";
    LC_TIME = "en_US.UTF-8";
  };
  # ----------------------------------------------------------------------------

  # ╔═╗╔═╗╔═╗╦ ╦╦═╗╦╔╦╗╦ ╦
  # ╚═╗║╣ ║  ║ ║╠╦╝║ ║ ╚╦╝                                       SECURITY | SOPS
  # ╚═╝╚═╝╚═╝╚═╝╩╚═╩ ╩  ╩ ------------------------------------------------------ 
  imports = [ sops-nix.nixosModules.sops ];
  environment.systemPackages = with pkgs; [ sops age bitwarden-cli ];
  security = {
    protectKernelImage = true; # Prevent modification of running kernel image (disable if causing rare compatibility/debug issues)
    lockKernelModules = false; # Allow module loading after boot (enable if maximum security is desired & no new modules needed post-boot)

    apparmor.enable = true;    # Enable AppArmor MAC system (disable if causing app conflicts or using SELinux)
    audit.enable = false;      # Disable kernel audit framework (enable if on for forensic logging)
    auditd.enable = false;     # Disable user-space audit daemon (enable if on multi-user system)

    rtkit.enable = true;       # Real-timeKit daemon for audio priority (disable if not needed for low-latency audio/etc.)
    polkit.enable = true;      # PolicyKit for managing privileges (disable only on minimal systems without graphical sessions/privilege needs)

    pam = {
      enableSSHAgentAuth = true;                # Allow using ssh-agent for PAM auth
      services.login.enableGnomeKeyring = true; # Optional: unlock keyring on login 
      services.sudo.sshAgentAuth = true;        # Allow sudo to use ssh-agent 
    };

    sudo = {
      enable = true;                            # Enable sudo 
      execWheelOnly = true;                     # Only users in 'wheel' can sudo
      wheelNeedsPassword = true;                # Require password even for wheel users (fallback) 
    };

    users.groups.wheel.members = [ primaryUser ]; # Add primary user to wheel group
  };

  sops = {
    enable = true; 
    age.keyFile = "/var/lib/sops/age/keys.txt";
    age.sshKeyPaths = [];

    # Optional default secret file settings
    # defaultSopsFile = ./../../secrets/secrets.yaml;
    # defaultSopsFormat = "yaml";

    secrets = { # Placeholder for actual secrets
      # "my-secret" = { source = ./path/to/secret.enc.yaml; };
    };
  };
  # ----------------------------------------------------------------------------

  # ╦ ╦╔═╗╦═╗╔╦╗╦ ╦╔═╗╦═╗╔═╗  
  # ╠═╣╠═╣╠╦╝ ║║║║║╠═╣╠╦╝║╣                                  HARDWARE | SERVICES
  # ╩ ╩╩ ╩╩╚══╩╝╚╩╝╩ ╩╩╚═╚═╝ ---------------------------------------------------
  hardware = {
    enableAllFirmware = true;         # Needed for hardware detection
    opengl = {                        # Enable OpenGL graphics acceleration
      enable = true;                  # Enable base OpenGL support
      driSupport = true;              # Enable Direct Rendering Infrastructure
      driSupport32Bit = true;         # Enable DRI for 32-bit applications
    };
  }; 

  powerManagement = {
    enable = true;
    cpuFreqGovernor = "performance";  # Default assume desktop machine
  };

  services = {
    thermald.enable = true;           # Manage CPU thermals to prevent overheating
    fstrim.enable = true;             # Periodic SSD trimming for SSD health
    
    pipewire = {
      enable = true;                  # Enable the main Pipewire service
      alsa.enable = true;             # Provide ALSA interface via Pipewire
      alsa.support32Bit = true;       # Support 32-bit ALSA applications
      pulse.enable = true;            # Provide PulseAudio interface via Pipewire
      jack.enable = true;             # Provide JACK interface via Pipewire
    };
    pulseaudio.enable = false;        # Disable PulseAudio since it's provided by Pipewire

    openssh = {                       # Enable SSH server
      enable = true;                  # Enable SSH server
      ports = [ 22 ];                 # Listen on port 22
      permitRootLogin = "no";         # Disallow root login
      passwordAuthentication = false; # Disallow password authentication
    };
  };
  # ----------------------------------------------------------------------------

  # ╔╗╔╔═╗╔╦╗╦ ╦╔═╗╦═╗╦╔═╦╔╗╔╔═╗
  # ║║║║╣  ║ ║║║║ ║╠╦╝╠╩╗║║║║║ ╦                                      NETWORKING
  # ╝╚╝╚═╝ ╩ ╚╩╝╚═╝╩╚═╩ ╩╩╝╚╝╚═╝ -----------------------------------------------
  networking.firewall = {
    enable = true;              # Enable the system firewall
    allowPing = false;          # Disallow incoming ICMP ping requests
    allowedTCPPortRanges = [];  # No open TCP ports by default
    allowedUDPPortRanges = [];  # No open UDP ports by default
  }; 
  networking.hostName = machineName;
  networking.networkmanager.enable = true;
  # -------------------------------------------------------------------------


  # ╔═╗╦ ╦╔═╗╔╦╗╔═╗╔╦╗
  # ╚═╗╚╦╝╚═╗ ║ ║╣ ║║║                                        FILESYSTEMS | SWAP
  # ╚═╝ ╩ ╚═╝ ╩ ╚═╝╩ ╩ ---------------------------------------------------------
  supportedFilesystems = [ "btrfs" ];
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
  btrfs.autoScrub = { enable = true; interval = "weekly"; };
  swapDevices = [{ device = "/.swap/swapfile"; size = 4096; }];
  systemd.services.create-swap = {
    description = "Create swap file for BTRFS";
    serviceConfig.Type = "oneshot";
    wantedBy = [ "swap-swapfile.swap" ];
    script = ''
      set -e # Exit script on first error
      SWAP_FILE="/.swap/swapfile" # Hardcode the path for clarity
      SWAP_SIZE_MB=4096 # Define size, matching swapDevices

      # Ensure directory exists
      mkdir -p "$(dirname "$SWAP_FILE")"

      # Check if swapfile needs creation
      if ! [ -f "$SWAP_FILE" ]; then
        echo "Creating BTRFS swapfile at $SWAP_FILE..."
        # Create empty file
        truncate -s 0 "$SWAP_FILE"
        # Set No_COW attribute (CRITICAL for BTRFS swap)
        chattr +C "$SWAP_FILE"
        # Disable BTRFS compression for swap file
        btrfs property set "$SWAP_FILE" compression none
        # Allocate space efficiently
        fallocate -l ${SWAP_SIZE_MB}M "$SWAP_FILE" || \
          dd if=/dev/zero of="$SWAP_FILE" bs=1M count=${SWAP_SIZE_MB} status=progress
        # Set secure permissions
        chmod 0600 "$SWAP_FILE"
        # Format the file as swap space
        mkswap "$SWAP_FILE"
        echo "Swapfile created."
      else
        echo "Swapfile $SWAP_FILE already exists."
        # Ensure No_COW attribute is set even if file exists
        chattr +C "$SWAP_FILE"
      fi

      # Activation is handled by systemd via the swap-swapfile.swap unit
      # based on the `swapDevices` option. No need for `swapon` here.
    '';
  };
  # ----------------------------------------------------------------------------

  # ╔╗╔╦═╗ ╦
  # ║║║║╔╩╦╝                                                                 NIX
  # ╝╚╝╩╩ ╚═ -------------------------------------------------------------------
  nix.gc = {
    automatic = true;                       # Enable automatic garbage collection
    dates = "weekly";                       # Run garbage collection weekly
    options = "--delete-older-than 7d";     # Delete generations older than 7 days
  };

  # Nix settings for performance and configuration
  nix.settings = {
    experimental-features = [ 
      "nix-command"                         # Enable nix-command (nix-env, nix-build, nix-shell, etc.)
      "flakes"                              # Enable flakes 
    ];
    auto-optimise-store = true;             # Optimize /nix/store by hard-linking identical files
  };

  system.autoUpgrade = {
    enable = true;                          # Enable automatic upgrades
    flake = "github:nosvagor/vagari.os";    # URL of flake repo
    flags = [
      "--update-input" "nixpkgs"            # Update nixpkgs input before upgrading
      "--option" "build-use-sandbox" "true" # Sandbox is usually default
    ];
    dates = "04:00";                        # Time to run the upgrade daily
    randomizedDelaySec = "45min";           # Random delay to avoid thundering herd
  };
  # ----------------------------------------------------------------------------
} 