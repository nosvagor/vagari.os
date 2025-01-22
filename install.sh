#!/usr/bin/env bash

set -euo pipefail  # Exit on error

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
AUTO_MODE=false

# Print functions
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
    echo -e "${YELLOW}Version: 0.1.0${NC}\n"
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

# Helper functions
cleanup() {
    print_warning "Cleaning up..."
    umount -R /mnt 2>/dev/null || true
    cryptsetup close root 2>/dev/null || true
}

fail() {
    print_error "$1"
    cleanup
    exit 1
}

check_command() {
    if ! command -v "$1" >/dev/null 2>&1; then
        fail "Required command '$1' not found. Please install it first."
    fi
}

check_mounts() {
    print_step "Verifying mounts"
    if ! mountpoint -q /mnt; then
        fail "Root not mounted at /mnt"
    fi
    if ! mountpoint -q /mnt/boot; then
        fail "Boot not mounted at /mnt/boot"
    fi
}

verify_disk() {
    local disk=$1
    if [ ! -b "$disk" ]; then
        fail "Disk $disk not found or not a block device"
    fi
    
    # Check if disk is mounted
    if mount | grep -q "$disk"; then
        fail "Disk $disk is currently mounted. Please unmount it first."
    fi
}

setup_encryption() {
    local attempts=3
    local success=false
    
    while [ $attempts -gt 0 ] && [ "$success" = false ]; do
        print_warning "Encryption setup attempt $((4 - attempts)) of 3"
        if cryptsetup luksFormat "$ROOT_PART"; then
            success=true
        else
            attempts=$((attempts - 1))
            if [ $attempts -gt 0 ]; then
                print_warning "Failed to set up encryption. Retrying..."
            fi
        fi
    done
    
    if [ "$success" = false ]; then
        fail "Failed to set up disk encryption after 3 attempts"
    fi
    
    # Open the encrypted partition
    attempts=3
    success=false
    while [ $attempts -gt 0 ] && [ "$success" = false ]; do
        if cryptsetup luksOpen "$ROOT_PART" root; then
            success=true
        else
            attempts=$((attempts - 1))
            if [ $attempts -gt 0 ]; then
                print_warning "Failed to open encrypted partition. Retrying..."
            fi
        fi
    done
    
    if [ "$success" = false ]; then
        fail "Failed to open encrypted partition after 3 attempts"
    fi
}

# Set up trap for cleanup on script exit
trap cleanup EXIT

# Check for required commands
check_command parted
check_command cryptsetup
check_command mkfs.fat
check_command mkfs.btrfs
check_command nixos-generate-config
check_command nixos-install

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
        --auto)
            AUTO_MODE=true
            print_warning "Running in automatic mode with defaults" ;;
        --help)
            echo -e "\n${BOLD}Usage:${NC} $0 [OPTIONS]"
            echo -e "\n${BOLD}Options:${NC}"
            echo "  --hostname     Set hostname (default: $HOSTNAME)"
            echo "  --disk        Specify disk to install to (default: $DISK)"
            echo "  --username    Set username (default: $USERNAME)"
            echo "  --auto        Run with defaults (non-interactive)"
            echo "  --help        Show this help message"
            exit 0 ;;
        *) fail "Unknown parameter: $1" ;;
    esac
    shift
done

# Show available disks
echo -e "\n${BOLD}Available disks:${NC}"
lsblk

# Verify disk exists and is valid
verify_disk "$DISK"

# Confirm with user if not in auto mode
if [ "$AUTO_MODE" = false ]; then
    print_warning "This will erase all data on $DISK"
    read -p "Continue? [y/N] " -n 1 -r
    echo
    [[ ! $REPLY =~ ^[Yy]$ ]] && exit 1
fi

# 1. Partition disk
print_step "Partitioning disk"
print_substep "Creating partition table"

# Clear any existing partitions
wipefs -af "$DISK" || fail "Failed to clear disk"
sync

# Create new partition table
parted "$DISK" -- mklabel gpt || fail "Failed to create GPT label"
parted "$DISK" -- mkpart ESP fat32 1MiB 512MiB || fail "Failed to create ESP partition"
parted "$DISK" -- set 1 esp on || fail "Failed to set ESP flag"
parted "$DISK" -- mkpart root 512MiB 100% || fail "Failed to create root partition"

# Wait for partitions to be recognized
sync
sleep 2

# Get partition names
BOOT_PART="${DISK}1"
ROOT_PART="${DISK}2"

# Verify partitions exist
if [ ! -e "$BOOT_PART" ] || [ ! -e "$ROOT_PART" ]; then
    fail "Partitions not created properly"
fi

# 2. Setup encryption
print_step "Setting up encryption"
print_warning "You will be prompted for an encryption passphrase"
print_warning "Remember this passphrase - you'll need it to boot your system!"
setup_encryption

# 3. Format partitions
print_step "Formatting partitions"
print_substep "Formatting boot partition"
mkfs.fat -F 32 -n boot "$BOOT_PART" || fail "Failed to format boot partition"
print_substep "Formatting root partition with BTRFS"
mkfs.btrfs /dev/mapper/root || fail "Failed to format root partition"

# 4. Create BTRFS subvolumes
print_step "Creating BTRFS subvolumes"
mount /dev/mapper/root /mnt || fail "Failed to mount root for subvolume creation"
btrfs subvolume create /mnt/@ || fail "Failed to create @ subvolume"
btrfs subvolume create /mnt/@home || fail "Failed to create @home subvolume"
btrfs subvolume create /mnt/@nix || fail "Failed to create @nix subvolume"
btrfs subvolume create /mnt/@snapshots || fail "Failed to create @snapshots subvolume"
umount /mnt

# 5. Mount subvolumes
print_step "Mounting subvolumes"
mount -o subvol=@,compress=zstd,noatime /dev/mapper/root /mnt || fail "Failed to mount @ subvolume"
mkdir -p /mnt/{home,nix,.snapshots,boot}
mount -o subvol=@home,compress=zstd,noatime /dev/mapper/root /mnt/home || fail "Failed to mount @home subvolume"
mount -o subvol=@nix,compress=zstd,noatime /dev/mapper/root /mnt/nix || fail "Failed to mount @nix subvolume"
mount -o subvol=@snapshots,compress=zstd,noatime /dev/mapper/root /mnt/.snapshots || fail "Failed to mount @snapshots subvolume"
mount "$BOOT_PART" /mnt/boot || fail "Failed to mount boot partition"

# Verify mounts
check_mounts

# 6. Generate hardware config
print_step "Generating hardware configuration"
nixos-generate-config --root /mnt || fail "Failed to generate hardware configuration"

if [ ! -f "/mnt/etc/nixos/hardware-configuration.nix" ]; then
    fail "Hardware configuration file not found after generation"
fi

# Get LUKS UUID for configuration
ROOT_UUID=$(blkid -s UUID -o value "$ROOT_PART")
if [ -z "$ROOT_UUID" ]; then
    fail "Failed to get ROOT_UUID"
fi

# 7. Create basic configuration
print_step "Creating NixOS configuration"
cat > /mnt/etc/nixos/configuration.nix << EOF || fail "Failed to create configuration.nix"
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
nixos-install --root /mnt || fail "NixOS installation failed"

print_success "Installation complete!"
echo -e "\n${BOLD}Next steps:${NC}"
echo "1. Reboot your system"
echo "2. Log in as $USERNAME"
echo "3. Clone your vagari.os repo and rebuild" 