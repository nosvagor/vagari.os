#!/usr/bin/env bash

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'

# Default values
HOSTNAME="abbot"
AUTO_MODE=false
DISK=""
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
}

usage() {
    echo "Usage: $0 [OPTIONS]"
    echo "Options:"
    echo "  --auto         Run with defaults (non-interactive)"
    echo "  --hostname     Set hostname (default: abbot)"
    echo "  --disk         Specify disk to install to"
    echo "  --username     Set username (default: nosvagor)"
    echo "  --help         Show this help message"
}

setup_disk() {
    local disk=$1
    echo -e "${BLUE}Setting up encrypted disk...${NC}"
    
    # Create encrypted partition
    cryptsetup luksFormat "$disk"
    cryptsetup luksOpen "$disk" root
    
    # Format and mount
    mkfs.btrfs /dev/mapper/root
    mount /dev/mapper/root /mnt
    
    # Get UUID for configuration
    UUID=$(blkid -s UUID -o value "$disk")
}

install_system() {
    echo -e "${BLUE}Installing vagari.os...${NC}"
    
    # Clone repo if not exists
    if [ ! -d "vagari.os" ]; then
        git clone https://github.com/nosvagor/vagari.os.git
    fi
    cd vagari.os
    
    # Update configuration with UUID
    sed -i "s/YOUR-UUID/$UUID/" "machines/$HOSTNAME/configuration.nix"
    
    # Generate and copy hardware config
    nixos-generate-config --root /mnt
    cp /mnt/etc/nixos/hardware-configuration.nix "machines/$HOSTNAME/"
    
    # Install
    nixos-install --flake ".#$HOSTNAME"
}

main() {
    print_header
    
    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            --auto) AUTO_MODE=true ;;
            --hostname) HOSTNAME="$2"; shift ;;
            --disk) DISK="$2"; shift ;;
            --username) USERNAME="$2"; shift ;;
            --help) usage; exit 0 ;;
            *) echo "Unknown option: $1"; usage; exit 1 ;;
        esac
        shift
    done
    
    if [ "$AUTO_MODE" = false ]; then
        # Interactive mode
        read -p "Enter hostname [$HOSTNAME]: " input
        HOSTNAME=${input:-$HOSTNAME}
        
        if [ -z "$DISK" ]; then
            lsblk
            read -p "Enter disk to install to (e.g., /dev/nvme0n1): " DISK
        fi
    else
        # Auto mode needs disk specified
        if [ -z "$DISK" ]; then
            echo -e "${RED}Error: --disk required in auto mode${NC}"
            exit 1
        fi
    fi
    
    setup_disk "$DISK"
    install_system
    
    echo -e "${GREEN}Installation complete!${NC}"
    echo "Please reboot and run: sudo nixos-rebuild switch --flake .#$HOSTNAME"
}

main "$@" 