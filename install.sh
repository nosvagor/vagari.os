#!/usr/bin/env bash

# Check if running as root
[[ $EUID -ne 0 ]] && echo "This script must be run as root" && exit 1

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

# Default values
DISK="/dev/nvme0n1"
HOSTNAME="abbot"
USERNAME="nosvagor"

print_header() {
    echo -e "${BLUE}"
    echo '██╗   ██╗ █████╗  ██████╗  █████╗ ██████╗ ██╗    ██████╗ ███████╗'
    echo '██║   ██║██╔══██╗██╔════╝ ██╔══██╗██╔══██╗██║   ██╔═══██╗██╔════╝'
    echo '██║   ██║███████║██║  ███╗███████║██████╔╝██║   ██║   ██║███████╗'
    echo '╚██╗ ██╔╝██╔══██║██║   ██║██╔══██║██╔══██╗██║   ██║   ██║╚════██║'
    echo ' ╚████╔╝ ██║  ██║╚██████╔╝██║  ██║██║  ██║██║   ╚██████╔╝███████║'
    echo '  ╚═══╝  ╚═╝  ╚═╝ ╚═════╝ ╚═╝  ╚═╝╚═╝  ╚═╝╚═╝    ╚═════╝ ╚══════╝'
    echo -e "${NC}"
    echo -e "${BOLD}Welcome to vagari.os Installation${NC}"
    echo -e "${CYAN}A personalized NixOS configuration${NC}\n"
}

print_step() {
    echo -e "\n${BLUE}==>${NC} ${BOLD}$1${NC}"
}

print_substep() {
    echo -e "${CYAN}  ->${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}Warning:${NC} $1"
}

print_error() {
    echo -e "${RED}Error:${NC} $1"
}

print_success() {
    echo -e "${GREEN}Success:${NC} $1"
}

# Print header
print_header

# Parse arguments
while [[ $# -gt 0 ]]; do
  case $1 in
    --disk) 
        DISK="$2"
        print_substep "Using disk: ${BOLD}$DISK${NC}"
        shift ;;
    --hostname)
        HOSTNAME="$2"
        print_substep "Using hostname: ${BOLD}$HOSTNAME${NC}"
        shift ;;
    --username)
        USERNAME="$2"
        print_substep "Using username: ${BOLD}$USERNAME${NC}"
        shift ;;
    --help)
        echo -e "\n${BOLD}Usage:${NC} $0 [OPTIONS]"
        echo -e "\n${BOLD}Options:${NC}"
        echo "  --hostname     Set hostname (default: $HOSTNAME)"
        echo "  --disk        Specify disk to install to (default: $DISK)"
        echo "  --username    Set username (default: $USERNAME)"
        echo "  --help        Show this help message"
        exit 0 ;;
    *) print_error "Unknown parameter: $1"; exit 1 ;;
  esac
  shift
done

# Show available disks
echo -e "\n${BOLD}Available disks:${NC}"
lsblk

# Confirm with user
print_warning "This will erase all data on $DISK"
read -p "Continue? [y/N] " -n 1 -r
echo
[[ ! $REPLY =~ ^[Yy]$ ]] && exit 1

# 1. Partition disk
print_step "Partitioning disk"
print_substep "Creating partition table"
parted "$DISK" -- mklabel gpt
parted "$DISK" -- mkpart ESP fat32 1MB 512MB
parted "$DISK" -- set 1 esp on
parted "$DISK" -- mkpart root 512MB 100%

# 2. Setup encryption
print_step "Setting up encryption"
print_warning "You will be prompted for an encryption passphrase"
print_warning "Remember this passphrase - you'll need it to boot your system!"
cryptsetup luksFormat "${DISK}2"
cryptsetup luksOpen "${DISK}2" root

# 3. Format partitions
print_step "Formatting partitions"
print_substep "Formatting boot partition"
mkfs.fat -F 32 -n boot "${DISK}1"
print_substep "Formatting root partition with BTRFS"
mkfs.btrfs /dev/mapper/root

# 4. Create BTRFS subvolumes
print_step "Creating BTRFS subvolumes"
mount /dev/mapper/root /mnt
btrfs subvolume create /mnt/@
btrfs subvolume create /mnt/@home
btrfs subvolume create /mnt/@nix
btrfs subvolume create /mnt/@snapshots
umount /mnt

# 5. Mount subvolumes
print_step "Mounting subvolumes"
mount -o subvol=@,compress=zstd,noatime /dev/mapper/root /mnt
mkdir -p /mnt/{home,nix,.snapshots,boot}
mount -o subvol=@home,compress=zstd,noatime /dev/mapper/root /mnt/home
mount -o subvol=@nix,compress=zstd,noatime /dev/mapper/root /mnt/nix
mount -o subvol=@snapshots,compress=zstd,noatime /dev/mapper/root /mnt/.snapshots
mount /dev/disk/by-label/boot /mnt/boot

# 6. Generate hardware config
print_step "Generating hardware configuration"
nixos-generate-config --root /mnt

# Get LUKS UUID for configuration
ROOT_UUID=$(blkid -s UUID -o value "${DISK}2")

# 7. Create basic configuration
print_step "Creating NixOS configuration"
cat > /mnt/etc/nixos/configuration.nix << EOF
{ config, pkgs, ... }:
{
  imports = [ ./hardware-configuration.nix ];

  # Boot configuration
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # Encryption setup
  boot.initrd.luks.devices = {
    root = {
      device = "/dev/disk/by-uuid/${ROOT_UUID}";
      preLVM = true;
    };
  };

  # File systems
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

  networking.hostName = "$HOSTNAME";
  
  users.users.$USERNAME = {
    isNormalUser = true;
    extraGroups = [ "wheel" "networkmanager" ];
  };

  system.stateVersion = "23.11";
}
EOF

# 8. Install NixOS
print_step "Installing NixOS"
nixos-install --root /mnt

print_success "Installation complete!"
echo -e "\n${BOLD}Next steps:${NC}"
echo "1. Reboot your system"
echo "2. Log in as $USERNAME"
echo "3. Clone your vagari.os repo and rebuild" 