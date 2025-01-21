#!/usr/bin/env bash

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
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

setup_hardware_config() {
    local machine=$1
    echo -e "${BLUE}Setting up hardware configuration for ${machine}...${NC}"
    
    # Create machine directory if it doesn't exist
    mkdir -p "machines/${machine}"
    
    # Generate hardware configuration
    echo -e "${YELLOW}Generating hardware configuration...${NC}"
    nixos-generate-config --root /mnt
    
    if [ ! -f "/mnt/etc/nixos/hardware-configuration.nix" ]; then
        echo -e "${RED}Error: Failed to generate hardware configuration${NC}"
        exit 1
    }
    
    # Copy hardware configuration to machine directory
    echo -e "${GREEN}Copying hardware configuration to machines/${machine}/...${NC}"
    cp "/mnt/etc/nixos/hardware-configuration.nix" "machines/${machine}/"
    
    if [ ! -f "machines/${machine}/hardware-configuration.nix" ]; then
        echo -e "${RED}Error: Failed to copy hardware configuration${NC}"
        exit 1
    }
}

install_system() {
    echo -e "${BLUE}Installing vagari.os...${NC}"
    
    # Clone repo if not exists
    if [ ! -d "vagari.os" ]; then
        git clone https://github.com/nosvagor/vagari.os.git
        cd vagari.os
    fi
    
    # Setup hardware configuration
    setup_hardware_config "$HOSTNAME"
    
    # Update configuration with UUID
    echo -e "${YELLOW}Updating configuration with disk UUID...${NC}"
    sed -i "s/YOUR-UUID/$UUID/" "machines/$HOSTNAME/configuration.nix"
    
    # Install
    echo -e "${BLUE}Running NixOS installation...${NC}"
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
        echo -e "${BLUE}Available machines:${NC}"
        ls -1 machines/ | grep -v "shared"
        
        read -p "Enter hostname [$HOSTNAME]: " input
        HOSTNAME=${input:-$HOSTNAME}
        
        echo -e "${YELLOW}Available disks:${NC}"
        lsblk
        read -p "Enter disk to install to [${DISK}]: " input
        DISK=${input:-$DISK}
    else
        # Auto mode validation
        if [ ! -e "$DISK" ]; then
            echo -e "${RED}Error: Default disk $DISK not found${NC}"
            lsblk
            exit 1
        fi
    fi
    
    setup_disk "$DISK"
    install_system
    
    echo -e "${GREEN}Installation complete!${NC}"
    echo "Please reboot and run: sudo nixos-rebuild switch --flake .#$HOSTNAME"
}

main "$@" 