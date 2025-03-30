#!/usr/bin/env bash

# ##############################################################################
# vagari.os Installation Script
# Repository: https://github.com/nosvagor/vagari.os
# License: The Unlicense
VERSION="0.1.0"

# Description:
# This script prepares a target disk and bootstraps a NixOS installation
# using the vagari.os flake configuration. It handles the necessary imperative
# steps before handing off to the declarative NixOS installation process.
#
# WARNING: This script is destructive and will erase the target disk.
#
# Core Steps:
# 1. Parse arguments (target disk, hostname).
# 2. Partition the target disk (ESP and LUKS root).
# 3. Encrypt the root partition using LUKS.
# 4. Format partitions (ESP: FAT32, LUKS container: BTRFS).
# 5. Create BTRFS subvolumes (@, @home, @nix, @snapshots).
# 6. Mount filesystems under /mnt.
# 7. Generate NixOS hardware configuration.
# 8. Clone the vagari.os flake repository to /mnt/etc/nixos.
# 9. Inject the LUKS partition UUID into the machine-specific config.
# 10. Install NixOS using the local flake.
# 11. Prompt user for post-install steps (reboot, set password, place SOPS key).
#
# Features:
# - LUKS encryption for the root partition.
# - BTRFS filesystem with standard subvolume layout.
# - Installs NixOS declaratively from the vagari.os flake.
# ##############################################################################

## =============================================================================
## === PRINT ===================================================================
## =============================================================================

R="\033[0;31m" # Red
G="\033[0;32m" # Green
B="\033[1;34m" # Bold Blue
Y="\033[1;33m" # Bold Yellow
M="\033[1;35m" # Bold Magenta
E="\033[1m"    # Bold
C="\033[0;36m" # Cyan
F="\033[1;30m" # Black
N="\033[0m"    # Reset

## section prints --------------------------------------------------------------

# H1; start of a main function
print_H1() {
    echo -e "\n${Y}(>_) $1${N}"
}

# H2; start distinct step
print_H2() {
    echo -e "\n${B}(↓) $1${N}"
}

# Major warning / notification
print_warning() {
    echo -e "\n${Y}(!) $1${N}"
}

# script breaking error
print_error() {
    echo -e "${R}(x) $1${N}"
}

# end of successful main function
print_finish() {
    echo -e "\n${G}(✓✓) $1${N}"
}

print_faint() {
    echo -e "${F}$1${N}"
}

## Result prints ---------------------------------------------------------------

# H3; start sub-step
print_H3() {
    echo -e "${B}(↓)${N} $1"
}

# for inputs
print_question() {
    echo -e "${M}(?)${N} $1"
}

# for warnings / notifications
print_attention() {
    echo -e "${Y}(!)${N} $1"
}

# end of a step
print_success() {
    echo -e "${G}(✓)${N} $1"
}

## single variable prints ------------------------------------------------------

# for: hyperlinks, paths, pointers, etc.
print_link() {
    echo -e "${C}$1${N}"
}

# for: key variables, important results, misc.
print_tip() {
    echo -e "${Y}$1${N}"
}

## =============================================================================
## === SETUP ===================================================================
## =============================================================================

# default values ---------------------------------------------------------------
DISK="nvme0n1"
DISK_PATH="/dev/${DISK}"
HOSTNAME="abbot"
USERNAME="nosvagor"
REPO_URL="https://github.com/nosvagor/vagari.os.git"
REPO_DIR="/mnt/etc/nixos"

# script internal variables ----------------------------------------------------
BOOT_PART=""
ROOT_PART=""
ROOT_UUID=""
DRY_RUN=false

# argument parsing -------------------------------------------------------------
parse_arguments() {
    while [[ $# -gt 0 ]]; do
        case $1 in
        -d | --disk)
            [[ -z "${2:-}" ]] && fail "No disk specified for $1"
            DISK="$2"
            print_H3 "Target Disk: $(print_tip "$DISK_PATH")"
            shift 2
            ;;
        -h | --hostname)
            [[ -z "${2:-}" ]] && fail "No hostname specified for $1"
            HOSTNAME="$2"
            print_H3 "Target Hostname: $(print_tip "$HOSTNAME")"
            shift 2
            ;;
        -u | --username)
            [[ -z "${2:-}" ]] && fail "No username specified for $1"
            USERNAME="$2"
            print_H3 "Target Username: $(print_tip "$USERNAME")"
            shift 2
            ;;
        --dry-run)
            DRY_RUN=true
            print_warning "Dry-run mode enabled. No changes will be made."
            shift
            ;;
        --post-install)
            post_install_instructions
            exit 0
            shift
            ;;
        -h | --help)
            show_help
            exit 0
            ;;
        *)
            fail "Unknown parameter: $1"
            ;;
        esac
    done

    if [[ -z "$DISK" ]]; then
        print_error "Target disk must be specified using -d or --disk option."
        show_help
        exit 1
    fi

    # partition variables based on DISK type
    if [[ "$DISK" == *"nvme"* ]]; then
        # NVMe drive naming convention (e.g., /dev/nvme0n1p1)
        BOOT_PART="${DISK}p1"
        ROOT_PART="${DISK}p2"
    else
        # SATA/SCSI drive naming convention (e.g., /dev/sda1)
        BOOT_PART="${DISK}1"
        ROOT_PART="${DISK}2"
    fi

    if [[ $EUID -ne 0 && $DRY_RUN == false ]]; then
        print_error "This script must be run as root."
        exit 126
    fi
}

# traps -------------------------------------------------------

fail() {
    print_error "INSTALLATION FAILED: $1"
    print_H2 "Attempting cleanup..."

    # # Check before trying to unmount
    # if mountpoint -q /mnt; then
    #     umount -R /mnt || print_warning "Failed to unmount /mnt during cleanup."
    #     print_success "unmount ran"
    # else
    #     print_faint "/mnt not mounted, skipping unmount."
    # fi

    # Check before trying to close LUKS device
    # if [ -e /dev/mapper/root ]; then
    #     cryptsetup luksClose /dev/mapper/root || print_warning "Failed to close LUKS device /dev/mapper/root during cleanup."
    #     print_success "luks clean up ran"
    # else
    #     print_attention "/dev/mapper/root not found, skipping LUKS close."
    # fi

    exit 1
}

# ==============================================================================
# === DIALOGUES ================================================================
# ==============================================================================

script_start() {
    echo -e "$B"
    echo '  ██╗   ██╗ █████╗  ██████╗  █████╗ ██████╗ ██╗    ██████╗ ███████╗'
    echo '  ██║   ██║██╔══██╗██╔════╝ ██╔══██╗██╔══██╗██║   ██╔═══██╗██╔════╝'
    echo '  ██║   ██║███████║██║  ███╗███████║██████╔╝██║   ██║   ██║███████╗'
    echo '  ╚██╗ ██╔╝██╔══██║██║   ██║██╔══██║██╔══██╗██║   ██║   ██║╚════██║'
    echo '   ╚████╔╝ ██║  ██║╚██████╔╝██║  ██║██║  ██║██║   ╚██████╔╝███████║'
    echo '    ╚═══╝  ╚═╝  ╚═╝ ╚═════╝ ╚═╝  ╚═╝╚═╝  ╚═╝╚═╝    ╚═════╝ ╚══════╝'
    echo '       → -.   →  .-'\''.   →  .--.   →  .--.   →  .--.   →  .-'\''→'
    echo '        ::.\::::::::.\::::::::.\::::::::.\::::::::.\:::::::'
    echo -e "         →:.\:: $(print_tip "$REPO_URL")${B} :::::: →"
    echo '        ::::.\::::::::.\::::::::.\::::::::.\::::::::.\:::::'
    echo '       →  →   `--'\''  →   `.-'\''  →   `--'\''  →   `--'\''  →   `--'\'' →'
    print_H1 "Installation Script $(print_link "v$VERSION")"
}

show_help() {
    echo
    echo "Usage: $0 [-d <disk_device>] [-h <hostname>] [-u <username>] [--dry-run] [--help]"
    echo
    echo "  -d, --disk      Specify the target block device (e.g., nvme0n1, sda)"
    echo -e "                  $F(default: $(print_link "${DISK} -> ${DISK_PATH}")"
    echo
    echo "  -h, --hostname  Specify the NixOS configuration hostname from the flake"
    echo -e "                  $F(default: $(print_tip "${HOSTNAME}")"
    echo
    echo "  -u, --username  Specify the NixOS configuration username from the flake"
    echo -e "                  $F(default: $(print_tip "${USERNAME}")"
    echo
    echo "  --post-install  Show post-installation instructions."
    echo "  --dry-run       Show commands without executing them."
    echo "  --help          Show this help message."
    exit 0
}

post_install_instructions() {
    print_H1 "Post-Installation Instructions"

    print_H2 "1. Set Root Password (Recommended)"
    print_attention "Enter the installed system environment:"
    print_link "nixos-enter --root /mnt"
    print_attention "Inside the environment, set the root password:"
    print_tip "passwd root"
    print_tip "exit"
    echo

    print_H2 "2. Place SOPS Key (Required for Secrets)"
    print_attention "Ensure the system is still mounted at /mnt."
    print_attention "Retrieve your SOPS key (e.g., using $(print_tip "bw") if installed) and place it at:"
    print_tip "/mnt/etc/sops/key.txt"
    print_attention "Example using Bitwarden CLI (run this *outside* nixos-enter):"
    print_tip "bw get item sops-key --raw > /mnt/etc/sops/key.txt"
    print_attention "Set correct permissions (inside nixos-enter):"
    print_tip "nixos-enter --root /mnt -c 'chmod 600 /etc/sops/key.txt'"
    echo

    print_H2 "3. Unmount and Reboot"
    print_attention "After completing the steps above:"
    print_tip "umount -R /mnt"
    print_tip "reboot"
}

# ==============================================================================
# === UTILITY FUNCTIONS =======================================================
# ==============================================================================

prompt_yes_no() {
    local prompt_text
    # Combine the question prefix and the yes/no hint
    prompt_text="$(print_question "$1 "$G$E"y"$N$G"es"$N"/"$R$E"n"$N$R"o"$N": ")"
    while true; do
        read -p "$prompt_text" yn
        case $yn in
        [Yy]*) return 0 ;;                                       # Return success (0) for Yes
        [Nn]*) return 1 ;;                                       # Return failure (1) for No
        *) print_attention "Please answer yes (y) or no (n)." ;; # Re-prompt on invalid input
        esac
    done
}

# ==============================================================================
# === PARTITIONING =============================================================
# ==============================================================================

partition_disk() {
    print_H2 "Partitioning Disk: $DISK_PATH"
    print_faint "$(lsblk "$DISK_PATH")"

    # Check if disk exists
    if ! lsblk "$DISK_PATH" >/dev/null 2>&1; then
        fail "Disk $DISK_PATH not found."
    fi

    # Wipe existing signatures (optional but safer)
    path_print=$(print_link "$DISK_PATH")
    print_H3 "Wiping existing filesystem signatures on $path_print..."
    prompt_yes_no "Wipe signatures on $path_print?" || fail "Declined to wipe signatures on $path_print."
    if [ "$DRY_RUN" = true ]; then
        print_faint "DRY-RUN: Would run wipefs --all $path_print"
    else
        wipefs --all "$DISK_PATH" || print_warning "Failed to wipe signatures (maybe disk is clean?)"
    fi
    print_success "Wiped signatures on $path_print"

    print_H3 "Creating GPT partition table and partitions on $path_print..."
    prompt_yes_no "Partition $path_print using parted?" || fail "Declined to partition $path_print."
    # Define partition variables using the full disk path
    local boot_part_path=""
    local root_part_path=""
    if [[ "$DISK" == *"nvme"* ]]; then
        boot_part_path="${DISK_PATH}p1"
        root_part_path="${DISK_PATH}p2"
    else
        boot_part_path="${DISK_PATH}1"
        root_part_path="${DISK_PATH}2"
    fi
    print_H3 "Target Boot Partition: $(print_tip "$boot_part_path")"
    print_H3 "Target Root Partition: $(print_tip "$root_part_path")"

    # Store these globally if needed by other functions (or pass as args)
    BOOT_PART="$boot_part_path"
    ROOT_PART="$root_part_path"

    local parted_command="parted --script ${DISK_PATH} -- \
        mklabel gpt \
        mkpart ESP fat32 1MiB 1GiB \
        set 1 esp on \
        mkpart primary 1GiB 100% \
        print"

    if [ "$DRY_RUN" = true ]; then
        print_faint "DRY-RUN: Would execute parted script:"
        print_faint "$parted_command"
        print_faint "DRY-RUN: Would wait for partitions $BOOT_PART and $ROOT_PART to appear using udevadm settle."
    else
        # Execute parted
        eval "$parted_command" || fail "Failed to partition $DISK_PATH using parted."
        print_success "Parted script executed."

        # Attempt to sync partition table and wait for udev
        print_H3 "Waiting for kernel to recognize new partitions..."
        udevadm trigger --action=add --subsystem-match=block 2>/dev/null
        partprobe "$DISK_PATH" 2>/dev/null
        blockdev --rereadpt "$DISK_PATH" 2>/dev/null
        sync
        print_faint "Waiting up to 15 seconds for udev events to settle..."
        if udevadm settle --timeout=15; then
            print_faint "udev settled."
        else
            print_warning "udevadm settle timed out after 15s. Partitions might not be ready yet."
        fi
        # Add a small safety sleep just in case settle finishes slightly too early
        sleep 1
    fi

    # Verify partitions were created using the full path
    if ! lsblk "$BOOT_PART" >/dev/null 2>&1 || ! lsblk "$ROOT_PART" >/dev/null 2>&1; then
        if [ "$DRY_RUN" = false ]; then
            print_faint "Final lsblk output for debugging:"
            print_faint "$(lsblk "$DISK_PATH")"
            fail "Boot ($BOOT_PART) or Root ($ROOT_PART) partition not found after running parted and udevadm settle."
        else
            print_faint "DRY-RUN: Partitions $BOOT_PART or $ROOT_PART would be checked for existence after settle."
        fi
    fi
    print_success "Partitions $BOOT_PART and $ROOT_PART detected."

    print_faint "Post-partition lsblk output:"
    print_faint "$(lsblk "$DISK_PATH")"
    print_finish "Disk partitioning complete."
}

# ==============================================================================
# === ENCRYPTION ===============================================================
# ==============================================================================

setup_encryption() {
    print_H2 "Setting up LUKS Encryption on $ROOT_PART"

    # Double-check partition exists before proceeding
    if ! lsblk "$ROOT_PART" >/dev/null 2>&1; then
        if [ "$DRY_RUN" = false ]; then
            fail "Root partition $ROOT_PART not found before encryption setup."
        else
            print_faint "DRY-RUN: Root partition $ROOT_PART would be checked."
        fi
    fi

    print_H3 "Formatting $ROOT_PART with LUKS2 (argon2id)..."
    print_attention "You will be prompted to enter and confirm a passphrase."
    local luks_format_command="cryptsetup luksFormat --type luks2 --pbkdf argon2id --pbkdf-memory 1048576 --iter-time 5000 ${ROOT_PART}"

    prompt_yes_no "Format $ROOT_PART with LUKS? This is DESTRUCTIVE." || fail "Declined LUKS formatting."
    if [ "$DRY_RUN" = true ]; then
        print_faint "DRY-RUN: Would execute: $luks_format_command"
        ROOT_UUID="DRY-RUN-UUID"
    else
        eval "$luks_format_command" || fail "Failed to format $ROOT_PART with LUKS."
        print_success "LUKS formatting complete."

        print_H3 "Opening LUKS partition $ROOT_PART as /dev/mapper/root..."
        print_attention "You will be prompted for the passphrase again."
        cryptsetup open "$ROOT_PART" root || fail "Failed to open LUKS partition."
        print_success "LUKS partition opened."

        print_H3 "Retrieving LUKS partition UUID..."
        ROOT_UUID=$(blkid -s UUID -o value "$ROOT_PART")
        if [[ -z "$ROOT_UUID" ]]; then
            fail "Failed to retrieve UUID for $ROOT_PART."
        fi
    fi
    print_success "Found LUKS UUID: $(print_tip "$ROOT_UUID")"

    print_finish "Encryption setup complete with UUID: $(print_tip "$ROOT_UUID")"
}

# ==============================================================================
# === FILESYSTEM ===============================================================
# ==============================================================================

format_filesystems() {
    print_H2 "Formatting Filesystems"

    # Boot Partition (FAT32)
    print_H3 "Formatting Boot partition ($(print_link "$BOOT_PART")) as FAT32..."
    prompt_yes_no "Format $BOOT_PART as FAT32?" || fail "Declined boot partition formatting."
    if [ "$DRY_RUN" = true ]; then
        print_faint "DRY-RUN: Would execute: mkfs.fat -F 32 -n BOOT ${BOOT_PART}"
    else
        mkfs.fat -F 32 -n BOOT "${BOOT_PART}" || fail "Failed to format boot partition."
    fi
    print_success "Boot partition formatted."

    # Root Partition (BTRFS on LUKS container)
    print_H3 "Formatting LUKS container $(print_link "/dev/mapper/root") as BTRFS..."
    prompt_yes_no "Format /dev/mapper/root as BTRFS?" || fail "Declined root partition formatting."
    if [ "$DRY_RUN" = true ]; then
        print_faint "DRY-RUN: Would execute: mkfs.btrfs -L ROOT /dev/mapper/root"
    else
        mkfs.btrfs -L ROOT /dev/mapper/root || fail "Failed to format root partition."
    fi
    print_success "Root partition formatted."

    print_finish "Filesystem formatting complete."
}

create_subvolumes() {
    print_H2 "Creating BTRFS Subvolumes"
    local btrfs_mount_opts="defaults,compress=zstd,noatime"

    print_H3 "Mounting BTRFS root partition temporarily..."
    if [ "$DRY_RUN" = true ]; then
        print_faint "DRY-RUN: Would mount /dev/mapper/root to /mnt"
    else
        # Ensure /mnt exists and is empty (or handle existing mounts)
        mkdir -p /mnt
        # Mount the top-level BTRFS volume
        mount -t btrfs -o "${btrfs_mount_opts}" /dev/mapper/root /mnt || fail "Failed to mount BTRFS root temporarily."
        print_success "Temporary BTRFS mount successful."
    fi

    local subvolumes=("@" "@home" "@nix" "@snapshots" "@swap") # Matches core.nix + swap
    print_H3 "Creating subvolumes: $(print_link "${subvolumes[*]}")"
    for vol in "${subvolumes[@]}"; do
        local subvol_path="/mnt/${vol}"
        if [ "$DRY_RUN" = true ]; then
            print_faint "DRY-RUN: Would execute: btrfs subvolume create ${subvol_path}"
        else
            btrfs subvolume create "${subvol_path}" || fail "Failed to create subvolume ${vol}."
        fi
    done
    print_success "Created subvolume ${vol}."

    print_H3 "Unmounting temporary BTRFS root partition..."
    if [ "$DRY_RUN" = true ]; then
        print_faint "DRY-RUN: Would unmount /mnt"
    else
        umount /mnt || fail "Failed to unmount temporary BTRFS root."
        print_success "Temporary BTRFS unmount successful."
    fi
    print_finish "BTRFS subvolume creation complete."
}

mount_final_filesystems() {
    print_H2 "Mounting Final Filesystems"

    # Define base BTRFS mount options (adjust if needed, matches core.nix)
    local btrfs_opts="defaults,compress=zstd,noatime,space_cache=v2,autodefrag"
    local root_mnt_opts="${btrfs_opts},subvol=@,nodev,nosuid,noexec"
    local home_mnt_opts="${btrfs_opts},subvol=@home"
    local nix_mnt_opts="${btrfs_opts},subvol=@nix"
    local snapshots_mnt_opts="${btrfs_opts},subvol=@snapshots"
    local swap_mnt_opts="${btrfs_opts},subvol=@swap"

    print_H3 "Mounting root subvolume (@) to /mnt..."
    if [ "$DRY_RUN" = true ]; then
        print_faint "DRY-RUN: Would mount /dev/mapper/root with options ${root_mnt_opts} to /mnt"
    else
        mount -o "${root_mnt_opts}" /dev/mapper/root /mnt || fail "Failed to mount root subvolume."
    fi
    print_success "Root subvolume mounted."

    # Create mount points for other subvolumes + boot
    local mount_points=("/mnt/boot" "/mnt/home" "/mnt/nix" "/mnt/.snapshots" "/mnt/.swap")
    print_H3 "Creating mount point directories: ${mount_points[*]}"
    if [ "$DRY_RUN" = true ]; then
        print_faint "DRY-RUN: Would create directories: ${mount_points[*]}"
    else
        mkdir -p "${mount_points[@]}" || fail "Failed to create mount point directories."
    fi
    print_success "Mount point directories created."

    # Mount other subvolumes
    print_H3 "Mounting other BTRFS subvolumes..."
    if [ "$DRY_RUN" = true ]; then
        print_faint "DRY-RUN: Would mount @home, @nix, @snapshots, @swap"
    else
        mount -o "${home_mnt_opts}" /dev/mapper/root /mnt/home || fail "Failed to mount @home subvolume."
        mount -o "${nix_mnt_opts}" /dev/mapper/root /mnt/nix || fail "Failed to mount @nix subvolume."
        mount -o "${snapshots_mnt_opts}" /dev/mapper/root /mnt/.snapshots || fail "Failed to mount @snapshots subvolume."
        mount -o "${swap_mnt_opts}" /dev/mapper/root /mnt/.swap || fail "Failed to mount @swap subvolume."
    fi
    print_success "Other subvolumes mounted."

    # Mount Boot partition
    print_H3 "Mounting Boot partition ($BOOT_PART) to /mnt/boot..."
    if [ "$DRY_RUN" = true ]; then
        print_faint "DRY-RUN: Would mount $BOOT_PART to /mnt/boot"
    else
        mount "$BOOT_PART" /mnt/boot || fail "Failed to mount boot partition."
    fi
    print_success "Boot partition mounted."

    print_finish "Final filesystems mounted."
}

# ==============================================================================
# === NIXOS INSTALLATION =======================================================
# ==============================================================================

setup_nixos_config() {
    print_H2 "Setting up NixOS Configuration Files"
    local hardware_config_source="/mnt/etc/nixos/hardware-configuration.nix"
    local temp_hardware_config_dest="/mnt/tmp/hardware-configuration.nix" # Temporary location
    local final_hardware_config_dest="${REPO_DIR}/machines/${HOSTNAME}/hardware-configuration.nix"
    local nixos_config_dir="/mnt/etc/nixos" # Standard config dir

    # 1. Generate hardware configuration
    print_H3 "Generating hardware-configuration.nix..."
    if [ "$DRY_RUN" = true ]; then
        print_faint "DRY-RUN: Would run nixos-generate-config --root /mnt"
    else
        nixos-generate-config --root /mnt || fail "Failed to generate hardware configuration."
        if [ ! -f "$hardware_config_source" ]; then
            fail "hardware-configuration.nix not found after generation."
        fi
    fi
    print_success "hardware-configuration.nix generated."

    # 2. Move hardware configuration to a temporary location
    print_H3 "Temporarily moving hardware config to ${temp_hardware_config_dest}..."
    if [ "$DRY_RUN" = true ]; then
        print_faint "DRY-RUN: Would move $hardware_config_source to $temp_hardware_config_dest"
    else
        mkdir -p "$(dirname "$temp_hardware_config_dest")" || fail "Failed to create temporary directory /mnt/tmp."
        mv "$hardware_config_source" "$temp_hardware_config_dest" || fail "Failed to move hardware configuration to temporary location."
    fi
    print_success "Hardware configuration temporarily moved."

    # 3. Remove the original NixOS config directory
    print_H3 "Removing generated NixOS config directory ${nixos_config_dir}..."
    if [ "$DRY_RUN" = true ]; then
        print_faint "DRY-RUN: Would remove directory ${nixos_config_dir}"
    else
        if [ -d "$nixos_config_dir" ]; then
            rm -rf "$nixos_config_dir" || fail "Failed to remove existing ${nixos_config_dir} directory."
            print_success "Removed existing ${nixos_config_dir}."
        else
            print_faint "Directory ${nixos_config_dir} did not exist, skipping removal."
        fi
    fi

    # 4. Clone the vagari.os repository
    print_H3 "Cloning repository $REPO_URL to $REPO_DIR..."
    if [ "$DRY_RUN" = true ]; then
        print_faint "DRY-RUN: Would clone $REPO_URL into $REPO_DIR"
    else
        if ! command -v git &>/dev/null; then
            print_attention "git command not found. Attempting to install via nix-env..."
            nix-env -iA nixos.git || fail "Failed to install git. Cannot clone repository."
        fi
        git clone "$REPO_URL" "$REPO_DIR" || fail "Failed to clone repository into ${REPO_DIR}."
    fi
    print_success "Repository cloned."

    print_H3 "Moving hardware config from temporary location to ${final_hardware_config_dest}..."
    if [ "$DRY_RUN" = true ]; then
        print_faint "DRY-RUN: Would move $temp_hardware_config_dest to $final_hardware_config_dest"
    else
        if [ ! -f "$temp_hardware_config_dest" ]; then
            fail "Temporary hardware config $temp_hardware_config_dest not found!"
        fi
        mv "$temp_hardware_config_dest" "$final_hardware_config_dest" || fail "Failed to move hardware configuration to final destination."
    fi
    print_success "Hardware configuration moved to final location."

    # --- BEGIN ADDED GIT COMMANDS ---
    print_H3 "Adding hardware configuration to Git index..."
    if [ "$DRY_RUN" = true ]; then
        print_faint "DRY_RUN: Would configure git user, cd to $REPO_DIR, add machines/${HOSTNAME}/hardware-configuration.nix, and commit."
    else
        # --- BEGIN ADDED SAFE DIRECTORY CONFIG ---
        print_faint "Adding $REPO_DIR to git safe.directory config..."
        # This is needed because we are running as root and manipulating a repo
        git config --global --add safe.directory "$REPO_DIR" || print_warning "Failed to add $REPO_DIR to git safe.directory."
        # --- END ADDED SAFE DIRECTORY CONFIG ---

        # Configure git user locally for the commit command
        git -C "$REPO_DIR" config user.name "Vagari Installer" || print_warning "Failed to set git user.name"
        git -C "$REPO_DIR" config user.email "installer@vagari.local" || print_warning "Failed to set git user.email"

        git -C "$REPO_DIR" add -f "machines/${HOSTNAME}/hardware-configuration.nix" || fail "Failed to git add hardware configuration."
        # Commit the change so Nix definitely picks it up
        git -C "$REPO_DIR" commit -m "Add generated hardware configuration for ${HOSTNAME}" --no-gpg-sign --author="Vagari Installer <installer@vagari.local>" || fail "Failed to git commit hardware configuration."
    fi
    print_success "Hardware configuration added and committed in Git."
    # --- END ADDED GIT COMMANDS ---

    # 6. Inject the LUKS UUID
    local machine_config_file="${REPO_DIR}/machines/${HOSTNAME}/configuration.nix"
    local uuid_placeholder="YOUR-UUID"
    print_H3 "Injecting LUKS UUID ($ROOT_UUID) into ${machine_config_file} (replacing '$uuid_placeholder')..."
    if [ "$DRY_RUN" = true ]; then
        print_faint "DRY-RUN: Would replace '$uuid_placeholder' with '$ROOT_UUID' in $machine_config_file"
    else
        if [[ -z "$ROOT_UUID" || "$ROOT_UUID" == "DRY-RUN-UUID" ]]; then
            fail "Invalid ROOT_UUID ($ROOT_UUID). Cannot inject into configuration."
        fi
        if [ ! -f "$machine_config_file" ]; then
            fail "Machine configuration file $machine_config_file not found! Was the repo cloned correctly and does the host profile exist?"
        fi
        if ! grep -q "$uuid_placeholder" "$machine_config_file"; then
            if grep -q "$ROOT_UUID" "$machine_config_file"; then
                print_faint "LUKS UUID ($ROOT_UUID) seems to be already present in $machine_config_file. Skipping replacement."
            else
                fail "Placeholder '$uuid_placeholder' not found in $machine_config_file, and the correct UUID ($ROOT_UUID) is also not present. Cannot inject required LUKS UUID."
            fi
        else
            sed -i "s|$uuid_placeholder|$ROOT_UUID|g" "$machine_config_file" || fail "Failed to inject LUKS UUID using sed."
            if grep -q "$uuid_placeholder" "$machine_config_file"; then
                print_warning "UUID placeholder might still be present after replacement attempt in $machine_config_file"
                fail "UUID placeholder still present after sed replacement!"
            else
                print_success "LUKS UUID injected successfully."
            fi
        fi
    fi

    print_finish "NixOS configuration files prepared."
}

install_nixos() {
    print_H1 "Installing NixOS from Local Flake"
    local flake_path="git+file://${REPO_DIR}#${HOSTNAME}"
    local machine_config_file="${REPO_DIR}/machines/${HOSTNAME}/configuration.nix"

    print_H3 "Running nixos-install with flake: ${flake_path}..."
    print_attention "This step will take a while as it downloads and builds packages."
    print_attention "If this step fails, error logs will be saved to: $(print_link "$install_log_file")"

    if [ "$DRY_RUN" = true ]; then
        print_faint "DRY-RUN: Would check for existence of ${REPO_DIR}, ${REPO_DIR}/flake.nix, and ${machine_config_file}"
        print_faint "DRY-RUN: Would execute: nixos-install --root /mnt --flake ${flake_path} (stderr would be logged to ${install_log_file} on failure)"
    else
        print_H3 "Verifying configuration files before install..."
        if [ ! -d "${REPO_DIR}" ]; then
            fail "Repository directory ${REPO_DIR} not found!"
        fi
        print_success "Found repository directory: ${REPO_DIR}"

        if [ ! -f "${REPO_DIR}/flake.nix" ]; then
            fail "flake.nix not found in ${REPO_DIR}!"
        fi
        print_success "Found flake.nix: ${REPO_DIR}/flake.nix"

        if [ ! -f "${machine_config_file}" ]; then
            fail "Machine configuration file ${machine_config_file} not found!"
        fi
        print_success "Found machine config: ${machine_config_file}"
        ls -la /mnt/etc/nixos
        prompt_yes_no "Continue?" || fail "Declined to continue."
        print_success "Configuration files verified."

        print_H3 "Checking internet connection..."
        if ! ping -c 1 -W 5 8.8.8.8 &>/dev/null && ! ping -c 1 -W 5 1.1.1.1 &>/dev/null; then
            fail "No internet connection detected before NixOS install."
        fi
        print_success "Internet connection verified."


        print_H3 "Running nixos-install... nixos-install --show-trace --root /mnt --flake ${flake_path}"
        nixos-install --show-trace --root /mnt --flake "$flake_path" 
    fi

    print_finish "NixOS installation command completed."

    print_H2 "Setting User Password for '$USERNAME'"
    if [ "$DRY_RUN" = true ]; then
        print_faint "DRY-RUN: Would prompt for password for user '$USERNAME' and set it via nixos-enter chpasswd."
    else
        if [[ -z "$USERNAME" ]]; then
            fail "USERNAME variable is empty. Cannot set password."
        fi

        local password=""
        local password_confirm=""

        while true; do
            print_question "Enter new password for user '$USERNAME': "
            read -s password
            echo

            print_question "Confirm new password: "
            read -s password_confirm
            echo

            if [[ "$password" == "$password_confirm" ]]; then
                if [[ -z "$password" ]]; then
                    print_attention "Password cannot be empty. Please try again."
                else
                    break
                fi
            else
                print_error "Passwords do not match. Please try again."
            fi
        done

        print_H3 "Setting password for user '$USERNAME' inside the installed system..."
        echo "${USERNAME}:${password}" | nixos-enter --root /mnt chpasswd
        local chpasswd_exit_code=$?

        unset password
        unset password_confirm
        if [ $chpasswd_exit_code -ne 0 ]; then
            fail "Failed to set password for user '$USERNAME' using chpasswd (exit code: $chpasswd_exit_code)."
        fi

        print_success "Password for user '$USERNAME' set successfully."
    fi
}

# ███╗   ███╗ █████╗ ██╗███╗   ██╗
# ████╗ ████║██╔══██╗██║████╗  ██║
# ██╔████╔██║███████║██║██╔██╗ ██║
# ██║╚██╔╝██║██╔══██║██║██║╚██╗██║
# ██║ ╚═╝ ██║██║  ██║██║██║ ╚████║
# ╚═╝     ╚═╝╚═╝  ╚═╝╚═╝╚═╝  ╚═══╝
main() {
    set -euo pipefail
    trap 'fail "Installation interrupted by user."' INT TERM

    parse_arguments "$@"
    script_start

    partition_disk
    setup_encryption
    format_filesystems
    create_subvolumes
    mount_final_filesystems
    setup_nixos_config
    install_nixos

    post_install_instructions

    exit 0 # Explicitly exit successfully
}

# Execute main function if script is run directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
