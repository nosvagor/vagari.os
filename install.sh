#!/usr/bin/env bash

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

# Default values
HOSTNAME="abbot"
AUTO_MODE=false
DISK="/dev/nvme0n1"
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

usage() {
    echo -e "\n${BOLD}Usage:${NC} $0 [OPTIONS]"
    echo -e "\n${BOLD}Options:${NC}"
    echo "  --auto         Run with defaults (non-interactive)"
    echo "  --hostname     Set hostname (default: $HOSTNAME)"
    echo "  --disk         Specify disk to install to (default: $DISK)"
    echo "  --username     Set username (default: $USERNAME)"
    echo "  --help         Show this help message"
    echo
}

setup_disk() {
    local disk=$1
    print_step "Setting up encrypted disk: ${BOLD}$disk${NC}"
    
    # Check if disk exists
    if [ ! -e "$disk" ]; then
        print_error "Disk $disk not found"
        echo -e "\n${BOLD}Available disks:${NC}"
        lsblk
        exit 1
    fi
    
    # Unmount all partitions from the disk
    print_substep "Checking for mounted partitions..."
    if mount | grep -q "$disk"; then
        print_warning "Found mounted partitions, unmounting..."
        sudo umount -l "${disk}"* 2>/dev/null || true
        sleep 1
        print_success "Partitions unmounted"
    fi
    
    # Kill any processes using the disk
    print_substep "Checking for processes using the disk..."
    if sudo fuser -m "${disk}"* >/dev/null 2>&1; then
        print_warning "Found processes using disk, terminating..."
        sudo fuser -k "${disk}"*
        sleep 1
        print_success "Processes terminated"
    fi
    
    # Create encrypted partition
    print_substep "Creating encrypted partition..."
    print_warning "You will be prompted for an encryption passphrase"
    print_warning "Remember this passphrase - you'll need it to boot your system!"
    cryptsetup luksFormat "$disk"
    cryptsetup luksOpen "$disk" root
    
    # Format and mount
    print_substep "Formatting with BTRFS..."
    mkfs.btrfs /dev/mapper/root
    print_substep "Mounting filesystem..."
    mount /dev/mapper/root /mnt
    
    # Get UUID for configuration
    UUID=$(blkid -s UUID -o value "$disk")
    print_success "Disk setup complete"
}

setup_hardware_config() {
    local machine=$1
    print_step "Setting up hardware configuration for ${BOLD}$machine${NC}"
    
    # Create machine directory if it doesn't exist
    print_substep "Creating machine directory..."
    mkdir -p "machines/${machine}"
    
    # Generate hardware configuration
    print_substep "Generating hardware configuration..."
    nixos-generate-config --root /mnt
    
    if [ ! -f "/mnt/etc/nixos/hardware-configuration.nix" ]; then
        print_error "Failed to generate hardware configuration"
        exit 1
    fi
    
    # Copy hardware configuration to machine directory
    print_substep "Copying hardware configuration..."
    cp "/mnt/etc/nixos/hardware-configuration.nix" "machines/${machine}/"
    
    if [ ! -f "machines/${machine}/hardware-configuration.nix" ]; then
        print_error "Failed to copy hardware configuration"
        exit 1
    fi
    
    print_success "Hardware configuration complete"
}

install_system() {
    print_step "Installing vagari.os"
    
    # First generate hardware config
    setup_hardware_config "$HOSTNAME"
    
    # Then clone repo and enter directory
    print_substep "Cloning configuration repository..."
    if [ ! -d "vagari.os" ]; then
        git clone https://github.com/nosvagor/vagari.os.git
    fi
    cd vagari.os
    
    # Create machine directory if needed
    mkdir -p "machines/$HOSTNAME"
    
    # Copy hardware config to repo
    print_substep "Copying hardware configuration to repo..."
    cp "/mnt/etc/nixos/hardware-configuration.nix" "machines/$HOSTNAME/"
    
    # Update configuration with UUID
    print_substep "Updating configuration with disk UUID..."
    sed -i "s/YOUR-UUID/$UUID/" "machines/$HOSTNAME/configuration.nix"
    
    # Install
    print_step "Running NixOS installation..."
    nixos-install --flake ".#$HOSTNAME"
}

main() {
    print_header
    
    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            --auto) 
                AUTO_MODE=true
                print_warning "Running in automatic mode with defaults" ;;
            --hostname)
                HOSTNAME="$2"
                print_substep "Using hostname: ${BOLD}$HOSTNAME${NC}"
                shift ;;
            --disk)
                DISK="$2"
                print_substep "Using disk: ${BOLD}$DISK${NC}"
                shift ;;
            --username)
                USERNAME="$2"
                print_substep "Using username: ${BOLD}$USERNAME${NC}"
                shift ;;
            --help) usage; exit 0 ;;
            *) print_error "Unknown option: $1"; usage; exit 1 ;;
        esac
        shift
    done
    
    if [ "$AUTO_MODE" = false ]; then
        # Interactive mode - disk selection
        echo -e "\n${BOLD}Available disks:${NC}"
        lsblk
        read -p "Enter disk to install to [${DISK}]: " input
        DISK=${input:-$DISK}
        print_substep "Selected disk: ${BOLD}$DISK${NC}"
    else
        # Auto mode validation
        if [ ! -e "$DISK" ]; then
            print_error "Default disk $DISK not found"
            echo -e "\n${BOLD}Available disks:${NC}"
            lsblk
            exit 1
        fi
    fi
    
    setup_disk "$DISK"
    install_system
    
    print_success "Installation complete!"
    echo -e "\n${BOLD}Next steps:${NC}"
    echo "1. Reboot your system"
    echo "2. Run: sudo nixos-rebuild switch --flake .#$HOSTNAME"
}

main "$@" 