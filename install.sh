#!/usr/bin/env bash

# ##############################################################################
# vagari.os Installation Script
VERSION="0.2.0-alpha"
# Author: nosvagor
# Repository: https://github.com/nosvagor/vagari.os
# License: The Unlicense

# Description:
# This script automates the installation of vagari.os, a personalized NixOS
# environment. It handles disk partitioning, encryption, filesystem setup,
# and base system configuration.
#
# Features:
# - LUKS encryption with header backup
# - BTRFS filesystem with optimized subvolumes
# - Automated NixOS configuration
# - Post-install setup
#
# Usage:
# Run as root: sudo ./install.sh [OPTIONS]
# Options:
#   -d, --disk      Specify disk to install to (default: /dev/nvme0n1)
#   -h, --hostname  Set hostname (default: abbot)
#   -u, --username  Set username (default: nosvagor)
#   --debug         Enable verbose output for debugging
#   --post          Run post-install steps only
#   --dry-run       Show what would be done without making changes
#   --help          Show this help message
# ##############################################################################

# Colors for output ============================================================
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'
# ==============================================================================

# Default values ===============================================================
DISK="/dev/nvme0n1"
HOSTNAME="abbot"
USERNAME="nosvagor"
DRY_RUN=false
POST_ONLY=false
BOOT_PART="${DISK}1"
ROOT_PART="${DISK}2"
ROOT_UUID=""
LOG_FILE="/tmp/vagari-os-install.log"

# Initial Check ================================================================
set -euo pipefail  # Exit on error
[[ $EUID -ne 0 ]] && echo -e "${RED}This script must be run as root [Error: ROOT-001] ${NC}" && exit 126

# Traps ========================================================================
trap cleanup EXIT
trap 'fail "Installation interrupted [Error: INT-001]"' INT TERM


# ==============================================================================

# Argument parsing =============================================================
parse_arguments() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            -d|--disk)
                if [ "$2" = "" ]; then
                    fail "No disk specified for $1 [Error: ARG-001]"
                fi
                DISK="$2"
                print_substep "Using disk: ${BOLD}$DISK${NC}"
                shift 2 ;;
            -h|--hostname)
                if [ "$2" = "" ]; then
                    fail "No hostname specified for $1 [Error: ARG-002]"
                fi
                HOSTNAME="$2"
                print_substep "Using hostname: ${BOLD}$HOSTNAME${NC}"
                shift 2 ;;
            -u|--username)
                if [ "$2" = "" ]; then
                    fail "No username specified for $1 [Error: ARG-003]"
                fi
                USERNAME="$2"
                print_substep "Using username: ${BOLD}$USERNAME${NC}"
                shift 2 ;;
            --debug)
                set -x
                print_warning "Debug mode enabled"
                shift ;;
            --post)
                POST_ONLY=true
                print_warning "Running post-install steps only"
                shift ;;
            --dry-run)
                DRY_RUN=true
                print_warning "Running in dry-run mode - no changes will be made"
                shift ;;
            --help)
                show_help
                exit 0 ;;
            *)
                fail "Unknown parameter: $1 [Error: ARG-004]" ;;
        esac
    done
}

# ==============================================================================

# Print functions ==============================================================
print_header() {
    echo -e "$BLUE"
    echo '  ██╗   ██╗ █████╗  ██████╗  █████╗ ██████╗ ██╗    ██████╗ ███████╗'
    echo '  ██║   ██║██╔══██╗██╔════╝ ██╔══██╗██╔══██╗██║   ██╔═══██╗██╔════╝'
    echo '  ██║   ██║███████║██║  ███╗███████║██████╔╝██║   ██║   ██║███████╗'
    echo '  ╚██╗ ██╔╝██╔══██║██║   ██║██╔══██║██╔══██╗██║   ██║   ██║╚════██║'
    echo '   ╚████╔╝ ██║  ██║╚██████╔╝██║  ██║██║  ██║██║   ╚██████╔╝███████║'
    echo '    ╚═══╝  ╚═╝  ╚═╝ ╚═════╝ ╚═╝  ╚═╝╚═╝  ╚═╝╚═╝    ╚═════╝ ╚══════╝'
    echo '       → -.   →  .-'\''.   →  .--.   →  .--.   →  .--.   →  .-'\''→'
    echo '        ::.\::::::::.\::::::::.\::::::::.\::::::::.\:::::::'
    echo -e "         →:.\:: ${YELLOW}https://github.com/nosvagor/vagari.os${NC} :::::: →"
    echo '        ::::.\::::::::.\::::::::.\::::::::.\::::::::.\:::::'
    echo '       →  →   `--'\''  →   `.-'\''  →   `--'\''  →   `--'\''  →   `--'\'' →'
    echo -e "$NC"
    echo -e "${BOLD}Welcome to vagari.os Installation${NC}"
    echo -e "${YELLOW}Version: ${VERSION}${NC}\n"
    echo -e "Run with ${BOLD}--help${NC} for usage information\n"
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

print_next_steps() {
    echo -e "\n${BOLD}Next steps:${NC}"
    echo "1. Reboot your system"
    echo "2. Log in as $USERNAME"
    echo "3. Review and customize your vagari.os configuration in /etc/nixos/vagari.os"
    echo "4. Run '${GREEN}nixos-rebuild switch${NC}' to apply any configuration changes"
    echo -e "\n${BOLD}Encryption Recovery Info:${NC}"
    echo "1. LUKS header backup stored at /mnt/etc/luks/header.img"
    echo "2. To restore header: cryptsetup luksHeaderRestore <device> --header-backup-file <backup-file>"
    echo "3. To add new key: cryptsetup luksAddKey <device>"
    echo "4. To change passphrase: cryptsetup luksChangeKey <device>"
}

# Add after print_functions section
show_help() {
    echo -e "${BOLD}Usage:${NC} $0 [OPTIONS]"
    echo
    echo -e "${BOLD}Options:${NC}"
    echo "  -d, --disk      Specify disk to install to (default: /dev/nvme0n1)"
    echo "  -h, --hostname  Set hostname (default: abbot)"
    echo "  -u, --username  Set username (default: nosvagor)"
    echo "  --debug         Enable verbose output for debugging"
    echo "  --post          Run post-install steps only"
    echo "  --dry-run       Show what would be done without making changes"
    echo "  --help          Show this help message"
    echo
    echo -e "${BOLD}Examples:${NC}"
    echo "  $0 --disk /dev/sda --hostname myhost --username myuser"
    echo "  $0 --post  # Run only post-install steps"
    echo
    echo -e "${BOLD}Note:${NC} This script must be run as root"
}

# Add at end of script, before final success message
print_final_summary() {
    local duration=$SECONDS
    echo -e "\n${BLUE}=== Installation Summary ===${NC}"
    echo -e "Status: ${GREEN}Success${NC}"
    echo -e "Duration: $((duration / 60)) minutes and $((duration % 60)) seconds"
    echo -e "Disk: ${DISK}"
    echo -e "Hostname: ${HOSTNAME}"
    echo -e "Username: ${USERNAME}"
    echo -e "Encryption: ${GREEN}Enabled${NC}"
    echo -e "Filesystem: BTRFS with optimized subvolumes"
    echo -e "Log file: ${LOG_FILE}"
    echo -e "\n${YELLOW}Remember to store your LUKS header backup in a safe place!${NC}"
}

# Helper functions
cleanup() {
    # Prevent multiple cleanup executions
    if [[ -n "${CLEANUP_DONE:-}" ]]; then
        return
    fi
    CLEANUP_DONE=1

    print_warning "Cleaning up and rolling back changes..."

    # Unmount in reverse order
    if mountpoint -q /mnt; then
        print_substep "Unmounting filesystems"
        umount -R /mnt 2>/dev/null || {
            print_warning "Failed to unmount /mnt"
            lsof /mnt || true
        }
    fi

    # Close encrypted devices
    if cryptsetup status root >/dev/null 2>&1; then
        print_substep "Closing encrypted devices"
        cryptsetup close root 2>/dev/null || {
            print_warning "Failed to close encrypted device"
            dmsetup info root || true
        }
    fi

    # Remove partitions if they exist
    if [ "$BOOT_PART" != "" ] && [ -b "$BOOT_PART" ]; then
        print_substep "Removing boot partition"
        wipefs --all "$BOOT_PART" 2>/dev/null || {
            print_warning "Failed to wipe boot partition"
            lsblk "$BOOT_PART" || true
        }
    fi

    if [ "$ROOT_PART" != "" ] && [ -b "$ROOT_PART" ]; then
        print_substep "Removing root partition"
        wipefs --all "$ROOT_PART" 2>/dev/null || {
            print_warning "Failed to wipe root partition"
            lsblk "$ROOT_PART" || true
        }
    fi

    # Remove temporary files
    print_substep "Cleaning up temporary files"
    rm -rf /tmp/vagari-os-* 2>/dev/null || true
    rm -rf /mnt/etc/nixos/vagari.os 2>/dev/null || true

    # Close network connections
    print_substep "Closing network connections"
    if command -v nmcli >/dev/null 2>&1; then
        nmcli connection down "$(nmcli -t -f NAME connection show --active)" 2>/dev/null || {
            print_warning "Failed to close network connections"
            nmcli connection show --active || true
        }
    fi

    print_warning "Cleanup and rollback completed. System returned to pre-installation state."
}

fail() {
    local error_code=""
    if [[ "$1" =~ \[Error: ]]; then
        error_code=$(echo "$1" | grep -oP '\[Error: \K[^\]]+')
    fi

    # Call cleanup first
    cleanup

    print_error "$1"
    echo -e "\n${RED}Error Details:${NC}"
    echo "Timestamp: $(date)"
    echo "Script Version: $VERSION"
    echo "Error Code: ${error_code:-UNKNOWN}"
    echo "Disk: $DISK"
    echo "Hostname: $HOSTNAME"
    echo "Username: $USERNAME"
    echo "System Info:"
    echo "  Memory: $(free -h | awk '/^Mem:/{print $2}')"
    echo "  CPU: $(lscpu | grep 'Model name' | cut -d':' -f2 | xargs)"
    echo "  Disk Usage: $(df -h /mnt)"

    exit 1
}

show_progress() {
    local pid=$1
    local msg=$2
    local delay=0.75
    local spin='-\|/'
    echo -n "  ${CYAN}${msg}... ${NC}"
    while kill -0 "$pid" 2>/dev/null; do
        local temp
        temp=${spin#?}
        printf " [%c]  " "$spin"
        local spin=$temp${spin%"$temp"}
        sleep "$delay"
        printf "\b\b\b\b\b\b"
    done
    printf "    \b\b\b\b"
    echo -e "\r  ${GREEN}✓${NC} ${msg} completed"
}

print_to_log() {
    local timestamp
    timestamp=$(date "+%Y-%m-%d %H:%M:%S")
    echo "[$timestamp] $1" >> "$LOG_FILE"
}

print_section() {
    local msg=$1
    echo -e "\n${BLUE}=== ${msg} ===${NC}"
    print_to_log "=== ${msg} ==="
}

print_final_summary() {
    local duration=$SECONDS
    echo -e "\n${BLUE}=== Installation Summary ===${NC}"
    echo -e "Status: ${GREEN}Success${NC}"
    echo -e "Duration: $((duration / 60)) minutes and $((duration % 60)) seconds"
    echo -e "Disk: ${DISK}"
    echo -e "Hostname: ${HOSTNAME}"
    echo -e "Username: ${USERNAME}"
    echo -e "Encryption: ${GREEN}Enabled${NC}"
    echo -e "Filesystem: BTRFS with optimized subvolumes"
    echo -e "Log file: ${LOG_FILE}"
    echo -e "\n${YELLOW}Remember to store your LUKS header backup in a safe place!${NC}"
}

# ============================================================================

# Helper functions ==============================================================
check_command() {
    if ! command -v "$1" >/dev/null 2>&1; then
        fail "Required command '$1' not found. Please install it first."
    fi
}

check_mounts() {
    print_step "Verifying mounts"
    if ! mountpoint -q /mnt; then
        fail "Root partition not mounted at /mnt. [Error: MOUNT-001]
        \nCurrent mounts:\n$(mount | grep /mnt)
        \nPlease verify the root partition is properly mounted."
    fi
    if ! mountpoint -q /mnt/boot; then
        fail "Boot partition not mounted at /mnt/boot. [Error: MOUNT-002]
        \nCurrent mounts:\n$(mount | grep /mnt/boot)
        \nPlease verify the boot partition is properly mounted."
    fi
}

verify_disk() {
    local disk
    disk=$1
    if [ ! -b "$disk" ]; then
        fail "Disk $disk not found or not a block device [Error: DISK-001]"
    fi

    # Check if disk is mounted
    if mount | grep -q "$disk"; then
        fail "Disk $disk is currently mounted. [Error: DISK-002]
        \nMounted partitions:\n$(mount | grep "$disk")
        \nPlease unmount all partitions on $disk before proceeding."
    fi
}

add_luks_key() {
    print_substep "Adding additional LUKS key"
    cryptsetup luksAddKey "$ROOT_PART" || print_warning "Failed to add additional key"
}

verify_encryption() {
    print_substep "Verifying encryption setup"
    if ! cryptsetup isLuks "$ROOT_PART"; then
        fail "Partition is not LUKS formatted"
    fi
    if ! cryptsetup status root; then
        fail "Encrypted partition not opened correctly"
    fi
    print_success "Encryption verified"
}

setup_encryption() {
    if [ "$DRY_RUN" = true ]; then
        print_substep "Would set up LUKS encryption on $ROOT_PART"
        return 0
    fi

    local attempts=3
    local success=false

    # Format the partition with LUKS
    while [ "$attempts" -gt 0 ] && [ "$success" = false ]; do
        print_warning "Encryption setup attempt $((4 - attempts)) of 3"
        if cryptsetup luksFormat "$ROOT_PART"; then
            success=true
            # Backup LUKS header
            print_substep "Backing up LUKS header"
            mkdir -p /mnt/etc/luks
            cryptsetup luksHeaderBackup "$ROOT_PART" --header-backup-file /mnt/etc/luks/header.img
            print_warning "Store this backup in a safe place! You'll need it for recovery."
            # Add additional key
            add_luks_key
            # Verify encryption
            verify_encryption
        else
            attempts=$((attempts - 1))
            if [ "$attempts" -gt 0 ]; then
                print_warning "Failed to set up encryption. Retrying..."
            fi
        fi
    done

    if [ "$success" = false ]; then
        fail "Failed to set up disk encryption after 3 attempts. [Error: LUKS-001]
        \nPossible causes:
        - Incorrect passphrase
        - Disk hardware issues
        - Insufficient memory for argon2id
        \nTry:
        1. Verify disk health with 'smartctl -a $DISK'
        2. Use simpler encryption parameters
        3. Check system memory with 'free -h'"
    fi

    # Open the encrypted partition
    attempts=3
    success=false
    while [ "$attempts" -gt 0 ] && [ "$success" = false ]; do
        if cryptsetup luksOpen "$ROOT_PART" root; then
            success=true
        else
            attempts=$((attempts - 1))
            if [ "$attempts" -gt 0 ]; then
                print_warning "Failed to open encrypted partition. Retrying..."
            fi
        fi
    done

    if [ "$success" = false ]; then
        fail "Failed to open encrypted partition after 3 attempts [Error: LUKS-002]"
    fi
}

setup_logging() {
    LOG_FILE="/tmp/vagari-os-install.log"
    rotate_logs
    echo -e "=== vagari.os Installation Log ===\n" > "$LOG_FILE"
    echo "Timestamp: $(date)" >> "$LOG_FILE"
    echo "Version: $VERSION" >> "$LOG_FILE"
    echo "Hostname: $HOSTNAME" >> "$LOG_FILE"
    echo "Username: $USERNAME" >> "$LOG_FILE"
    echo "Disk: $DISK" >> "$LOG_FILE"
    echo "System Info:" >> "$LOG_FILE"
    echo "  Memory: $(free -h | awk '/^Mem:/{print $2}')" >> "$LOG_FILE"
    echo "  CPU: $(lscpu | grep 'Model name' | cut -d':' -f2 | xargs)" >> "$LOG_FILE"
    echo "  Disk Usage: $(df -h)" >> "$LOG_FILE"
    echo -e "\n=== Installation Progress ===\n" >> "$LOG_FILE"
    exec > >(tee -a "$LOG_FILE") 2>&1
    print_substep "Logging installation to $LOG_FILE"
    print_warning "Full installation log available at $LOG_FILE"
}

# Add log rotation to prevent huge files
rotate_logs() {
    if [ -f "$LOG_FILE" ]; then
        mv "$LOG_FILE" "${LOG_FILE}.old"
    fi
}

verify_network() {
    print_step "Verifying network connection"
    local retries=3
    local success=false

    for ((i=1; i<=retries; i++)); do
        if ping -c 1 -W 5 8.8.8.8 &>/dev/null || ping -c 1 -W 5 1.1.1.1 &>/dev/null; then
            success=true
            break
        fi
        print_warning "Network check attempt $i of $retries failed"
        sleep 2
    done

    if [ "$success" = false ]; then
        fail "No internet connection detected [Error: NET-001]"
    fi
    print_success "Network connection verified"
}
# ============================================================================

# Options ======================================================================
setup_timezone() {
    print_step "Setting timezone"
    timedatectl list-timezones
    read -p "Enter timezone (e.g., America/New_York): " timezone
    if timedatectl set-timezone "$timezone"; then
        print_success "Timezone set to $timezone"
    else
        print_warning "Failed to set timezone"
    fi
}

encryption_options() {
    print_step "Disk Encryption Options"
    echo "1) Full disk encryption (recommended)"
    echo "2) No encryption"
    read -p "Select encryption option (1-2): " enc_choice

    case $enc_choice in
        1) setup_encryption ;;
        2) print_warning "Skipping disk encryption" ;;
        *) fail "Invalid encryption choice" ;;
    esac
}

post_install() {
    print_step "Running post-install steps"

    # Set up user password
    print_substep "Setting password for $USERNAME"
    passwd "$USERNAME" || print_warning "Failed to set password"

    # Install git and clone repo
    print_substep "Installing git and cloning vagari.os"
    nix-env -iA nixos.git || print_warning "Failed to install git"
    git clone https://github.com/nosvagor/vagari.os /mnt/etc/nixos/vagari.os || {
        print_warning "Failed to clone repository. [Error: GIT-001]
        \nPossible causes:
        - Network connectivity issues
        - GitHub API rate limiting
        - Disk space issues
        \nTry:
        1. Check network connection
        2. Wait and try again later
        3. Verify disk space with 'df -h'"
    }

    # Initialize flake
    print_substep "Initializing flake"
    nixos-rebuild switch --flake /mnt/etc/nixos/vagari-os#"${HOSTNAME}" || {
        print_warning "Failed to initialize flake. [Error: NIXOS-002]
        \nBuild log:\n$(tail -n 50 /mnt/var/log/nixos-rebuild.log)
        \nPossible causes:
        - Invalid flake configuration
        - Missing dependencies
        - Network connectivity issues
        \nTry:
        1. Review flake configuration
        2. Check network connection
        3. Run 'nix flake update'"
    }

    print_success "Post-install steps completed"
}

select_disk() {
    local disks
    mapfile -t disks < <(lsblk -d -n -l -o NAME,SIZE | awk '{print "/dev/"$1" "$2}')
    if [ ${#disks[@]} -eq 0 ]; then
        fail "No disks found"
    fi

    echo -e "\n${BOLD}Select installation disk:${NC}"
    PS3="Enter choice (1-${#disks[@]}): "
    select disk in "${disks[@]}"; do
        if [[ -n "$disk" ]]; then
            DISK=$(echo "$disk" | awk '{print $1}')
            print_substep "Selected disk: ${BOLD}$DISK${NC}"
            break
        else
            print_error "Invalid selection"
        fi
    done
}

# Validation ===================================================================
validate_system() {
    print_step "Validating system requirements"

    # Check minimum memory
    local min_memory=2048  # 2GB in MB
    local available_memory
    available_memory=$(free -m | awk '/^Mem:/{print $2}')
    if [ "$available_memory" -lt "$min_memory" ]; then
        fail "Insufficient memory. Required: ${min_memory}MB, Available: ${available_memory}MB [Error: MEM-001]"
    fi

    # Check CPU cores
    local min_cores=2
    local available_cores
    available_cores=$(nproc)
    if [ "$available_cores" -lt "$min_cores" ]; then
        fail "Insufficient CPU cores. Required: ${min_cores}, Available: ${available_cores}"
    fi

    # Check disk space
    local min_disk=20000  # 20GB in MB
    local available_disk
    available_disk=$(df -m --output=avail "$DISK" | tail -1)
    if [ "$available_disk" -lt "$min_disk" ]; then
        fail "Insufficient disk space. Required: ${min_disk}MB, Available: ${available_disk}MB"
    fi

    # Check internet speed
    print_substep "Checking internet connection speed"
    local min_speed=5  # 5Mbps
    local download_speed
    download_speed=$(curl -s https://speedtest.net/ | grep -oP 'download-speed:\s*\K[\d.]+')
    if (( $(echo "$download_speed < $min_speed" | bc -l) )); then
        print_warning "Slow internet connection detected. Download speed: ${download_speed}Mbps (Minimum recommended: ${min_speed}Mbps)"
    fi

    # Check available disk space for installation
    local install_space
    install_space=$(df -m /mnt 2>/dev/null | awk 'NR==2 {print $4}' || echo 0)
    if [ "$install_space" -lt 20000 ]; then  # 20GB minimum
        fail "Insufficient space for installation. Need at least 20GB [Error: SPACE-001]"
    fi
}

validate_partitions() {
    print_step "Validating partitions"

    if [ ! -b "$BOOT_PART" ]; then
        fail "Boot partition $BOOT_PART not found"
    fi

    if [ ! -b "$ROOT_PART" ]; then
        fail "Root partition $ROOT_PART not found"
    fi

    # Check partition sizes
    local boot_size
    boot_size=$(blockdev --getsize64 "$BOOT_PART")
    if [ "$boot_size" -lt $((1024 * 1024 * 1024)) ]; then  # 1GB
        fail "Boot partition is too small. Minimum size: 1GB"
    fi

    local root_size
    root_size=$(blockdev --getsize64 "$ROOT_PART")
    if [ "$root_size" -lt $((10 * 1024 * 1024 * 1024)) ]; then  # 10GB
        fail "Root partition is too small. Minimum size: 10GB"
    fi
}

# Add mount validation
validate_mounts() {
    print_step "Validating mounts"

    if ! mountpoint -q /mnt; then
        fail "Root partition not mounted at /mnt"
    fi

    if ! mountpoint -q /mnt/boot; then
        fail "Boot partition not mounted at /mnt/boot"
    fi

    # Check for sufficient free space
    local min_free_space=5000  # 5GB in MB
    local free_space
    free_space=$(df -m /mnt | awk 'NR==2{print $4}')
    if [ "$free_space" -lt "$min_free_space" ]; then
        fail "Insufficient free space on root partition. Required: ${min_free_space}MB, Available: ${free_space}MB"
    fi
}

# Add more validation checks
validate_commands() {
    print_step "Validating required commands"
    local required_commands=("cryptsetup" "parted" "btrfs" "nixos-generate-config" "nixos-install")
    for cmd in "${required_commands[@]}"; do
        if ! command -v "$cmd" >/dev/null 2>&1; then
            fail "Required command '$cmd' not found. Please install it first."
        fi
    done
}

validate_swap() {
    print_step "Validating swap space"
    local min_swap=2048  # 2GB in MB
    local available_swap
    available_swap=$(free -m | awk '/^Swap:/{print $2}')
    if [ "$available_swap" -lt "$min_swap" ]; then
        print_warning "Insufficient swap space. Recommended: ${min_swap}MB, Available: ${available_swap}MB"
    fi
}

# ==============================================================================

# ███╗   ███╗ █████╗ ██╗███╗   ██╗
# ████╗ ████║██╔══██╗██║████╗  ██║
# ██╔████╔██║███████║██║██╔██╗ ██║
# ██║╚██╔╝██║██╔══██║██║██║╚██╗██║
# ██║ ╚═╝ ██║██║  ██║██║██║ ╚████║
# ╚═╝     ╚═╝╚═╝  ╚═╝╚═╝╚═╝  ╚═══╝
if [ "$POST_ONLY" = true ]; then
    post_install
    exit 0
fi

# 0. Setup ---------------------------------------------------------------------
# This section handles initial setup tasks:
# - Prints header and version info
# - Sets up logging and argument parsing
# - Verifies disk and network connectivity
# - Validates system requirements
# - Initializes timezone and encryption options
print_header
setup_logging
parse_arguments "$@"
verify_disk "$DISK"
verify_network
setup_timezone
encryption_options
validate_system
validate_partitions
validate_mounts
validate_commands
validate_swap
print_section "Starting Installation"
# ------------------------------------------------------------------------------

# 1. Partition disk ------------------------------------------------------------
# This section handles disk partitioning:
# - Creates GPT partition table
# - Creates ESP and root partitions
# - Verifies partition alignment
print_step "Partitioning disk"
print_substep "Creating aligned partitions with parted"
parted --script "$DISK" \
    mklabel gpt \
    mkpart ESP fat32 1MiB 1GiB \
    set 1 esp on \
    mkpart primary 1GiB 100% \
    align-check optimal 1 \
    align-check optimal 2

# Verify partition alignment
if ! parted "$DISK" align-check optimal 1 && parted "$DISK" align-check optimal 2; then
    fail "Partition alignment failed. [Error: PART-001]
    \nCurrent partition table:\n$(parted "$DISK" print)
    \nPlease verify the disk geometry and try again."
fi
# ------------------------------------------------------------------------------

# 2. Setup encryption ----------------------------------------------------------
# This section handles LUKS encryption:
# - Formats root partition with LUKS2
# - Backups LUKS header
# - Opens encrypted partition
print_section "Encryption Setup"
print_substep "Setting up LUKS2 with argon2id"
cryptsetup luksFormat --type luks2 \
    --pbkdf argon2id \
    --pbkdf-memory 1048576 \
    --iter-time 5000 \
    "$ROOT_PART"
# ------------------------------------------------------------------------------

# 3. Format partitions ---------------------------------------------------------
# This section handles filesystem creation:
# - Formats boot partition as FAT32
# - Formats root partition as BTRFS
print_section "Formatting Partitions"
print_substep "Formatting boot partition"
mkfs.fat -F 32 -n boot "$BOOT_PART" || fail "Failed to format boot partition"
print_substep "Formatting root partition with BTRFS"
mkfs.btrfs /dev/mapper/root || fail "Failed to format root partition"
# ------------------------------------------------------------------------------

# 4. Create BTRFS subvolumes ---------------------------------------------------
# This section creates BTRFS subvolumes:
# - Creates @, @home, @nix, @snapshots, @var, @log, @swap subvolumes
print_section "Creating BTRFS Subvolumes"
mount /dev/mapper/root /mnt || fail "Failed to mount root for subvolume creation"
btrfs subvolume create /mnt/@
btrfs subvolume create /mnt/@home
btrfs subvolume create /mnt/@nix
btrfs subvolume create /mnt/@snapshots
btrfs subvolume create /mnt/@var
btrfs subvolume create /mnt/@log
btrfs subvolume create /mnt/@swap
umount /mnt
# ------------------------------------------------------------------------------

# 5. Mount subvolumes ----------------------------------------------------------
# This section mounts all subvolumes:
# - Mounts root subvolume with optimized options
# - Creates and mounts all other subvolumes
print_section "Mounting Subvolumes"
mount -o subvol=@,compress=zstd:3,noatime,space_cache=v2,autodefrag,nodev,nosuid,noexec /dev/mapper/root /mnt
mkdir -p /mnt/{home,nix,.snapshots,boot,var,log}
mount -o subvol=@home,compress=zstd,noatime,space_cache=v2 /dev/mapper/root /mnt/home || fail "Failed to mount @home subvolume"
mount -o subvol=@nix,compress=zstd,noatime,space_cache=v2 /dev/mapper/root /mnt/nix || fail "Failed to mount @nix subvolume"
mount -o subvol=@snapshots,compress=zstd,noatime,space_cache=v2 /dev/mapper/root /mnt/.snapshots || fail "Failed to mount @snapshots subvolume"
mount -o subvol=@var,compress=zstd,noatime,space_cache=v2 /dev/mapper/root /mnt/var || fail "Failed to mount @var subvolume"
mount -o subvol=@log,compress=zstd,noatime,space_cache=v2 /dev/mapper/root /mnt/log || fail "Failed to mount @log subvolume"
mount "$BOOT_PART" /mnt/boot || fail "Failed to mount boot partition"
# ------------------------------------------------------------------------------

# 6. Generate hardware config --------------------------------------------------
# This section generates hardware configuration:
# - Runs nixos-generate-config
# - Gets LUKS UUID for configuration
print_section "Generating Hardware Configuration"
nixos-generate-config --root /mnt || fail "Failed to generate hardware configuration"

if [ ! -f "/mnt/etc/nixos/hardware-configuration.nix" ]; then
    fail "Hardware configuration file not found after generation"
fi

ROOT_UUID=$(blkid -s UUID -o value "$ROOT_PART")
if [ "$ROOT_UUID" = "" ]; then
    fail "Failed to get ROOT_UUID"
fi
# ------------------------------------------------------------------------------

# 7. Create basic configuration ------------------------------------------------
# This section creates initial NixOS configuration:
# - Sets up bootloader, encryption, filesystems
# - Configures users and security settings
print_section "Creating NixOS Configuration"
cat > /mnt/etc/nixos/configuration.nix << EOF || fail "Failed to create configuration.nix"
{ config, pkgs, ... }:
{
  imports = [ ./hardware-configuration.nix ];

  # Boot configuration
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.loader.systemd-boot.configurationLimit = 10;
  boot.loader.systemd-boot.consoleMode = "max";
  boot.loader.systemd-boot.editor = false;

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

  # Audio configuration
  hardware.pulseaudio.enable = false;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    jack.enable = true;
  };

  networking.hostName = "$HOSTNAME";

  users.users.$USERNAME = {
    isNormalUser = true;
    extraGroups = [ "wheel" "networkmanager" ];
    hashedPasswordFile = "/etc/passwd/${USERNAME}";
    openssh.authorizedKeys.keys = [
        "ssh-ed25519 AAAAC3Nz..." # Add your public key
    ];
    packages = with pkgs; [
        age
        sops
        gnupg
    ];
  };

  system.stateVersion = "23.11";

  boot.kernelParams = [
    "lockdown=confidentiality"
    "module.sig_enforce=1"
    "slab_nomerge"
    "init_on_alloc=1"
    "init_on_free=1"
    "page_alloc.shuffle=1"
    "vsyscall=none"
    "debugfs=off"
    "oops=panic"
    "mce=0"
  ];

  boot.kernelLockdown = true;

  security.allowSimultaneousMultithreading = false;
  security.forcePageTableIsolation = true;
}
EOF
# ------------------------------------------------------------------------------

# 8. Install NixOS -------------------------------------------------------------
# This section performs the actual NixOS installation:
# - Runs nixos-install with flake configuration
print_section "Installing NixOS"
nixos-install --root /mnt --flake github:nosvagor/vagari-os#"${HOSTNAME}" || {
    fail "NixOS installation failed. [Error: NIXOS-001]"
}
# ------------------------------------------------------------------------------

# 9. Post-install --------------------------------------------------------------
# This section handles post-install tasks:
# - Sets user password
# - Clones vagari.os repository
# - Initializes flake configuration
print_section "Running Post-install Steps"
post_install
# ------------------------------------------------------------------------------

print_success "Installation complete!"
print_next_steps
