#!/usr/bin/env bash

# ##############################################################################
# vagari.os Installation Script (MINIMAL)
# Repository: https://github.com/nosvagor/vagari.os
# License: The Unlicense
VERSION="0.1.0-minimal"

# Description:
# This script prepares a target disk and bootstraps a NixOS installation
# using the vagari.os flake configuration. It handles the necessary imperative
# steps before handing off to the declarative NixOS installation process.
#
# WARNING: This script is destructive and will erase the target disk.
#
# Core Steps:
# 1. Set fixed variables (disk, hostname).
# 2. Partition the target disk (ESP and LUKS root).
# 3. Encrypt the root partition using LUKS.
# 4. Format partitions (ESP: FAT32, LUKS container: BTRFS).
# 5. Create BTRFS subvolumes (@, @home, @nix, @snapshots, @swap).
# 6. Mount filesystems under /mnt.
# 7. Generate NixOS hardware configuration.
# 8. Clone the vagari.os flake repository to /mnt/etc/nixos.
# 9. Inject the LUKS partition UUID into the machine-specific config.
# 10. Install NixOS using the local flake.
# 11. Set the user password.
# 12. Prompt user for post-install steps.
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
    echo -e "\n${G}(+++) $1${N}"
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
    echo -e "${G}(+)${N} $1"
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

DISK="nvme0n1"                 
DISK_PATH="/dev/${DISK}"
HOSTNAME="abbot"                 
USERNAME="nosvagor"              
REPO_URL="https://github.com/nosvagor/vagari.os"
REPO_DIR="/mnt/etc/nixos"

BOOT_PART=""
ROOT_PART=""
ROOT_UUID=""
ENABLE_ENCRYPTION=false 
ROOT_DEVICE=""          

set_partitions() {
    print_H3 "Setting partition variables based on Disk Type: $(print_tip "$DISK")"
    if [[ "$DISK" == *"nvme"* ]]; then
        BOOT_PART="${DISK_PATH}p1"
        ROOT_PART="${DISK_PATH}p2"
    else
        BOOT_PART="${DISK_PATH}1"
        ROOT_PART="${DISK_PATH}2"
    fi
    print_success "Set Boot Partition: $(print_tip "$BOOT_PART")"
    print_success "Set Root Partition: $(print_tip "$ROOT_PART")"
}

check_root() {
    if [[ $EUID -ne 0 ]]; then
        print_error "This script must be run as root."
        exit 126
    fi
    print_success "Running as root."
}


fail() {
    print_error "INSTALLATION FAILED: $1"
    print_H2 "Attempting cleanup..."
    umount -R /mnt || print_warning "Failed to unmount /mnt during cleanup."
    if [ "$ENABLE_ENCRYPTION" = true ]; then
        cryptsetup luksClose /dev/mapper/root || print_warning "Failed to close LUKS device /dev/mapper/root during cleanup."
    fi
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
    echo '       → -.   →  .-'\'''.   →  .--.   →  .--.   →  .--.   →  .-'\''→'
    echo '        ::.\::::::::.\::::::::.\::::::::.\::::::::.\:::::::'
    echo -e "         →:.\:: $(print_tip "$REPO_URL")${B} :::::: →"
    echo '        ::::.\::::::::.\::::::::.\::::::::.\::::::::.\:::::'
    echo '       →  →   `--'\''  →   `.-'\''  →   `--'\''  →   `--'\''  →   `--'\'' →'
    print_H1 "Minimal Installation Script $(print_link "v$VERSION")"
    print_attention "Using Hardcoded Settings:"
    print_H3 "Target Disk: $(print_tip "$DISK_PATH")"
    print_H3 "Target Hostname: $(print_tip "$HOSTNAME")"
    print_H3 "Target Username: $(print_tip "$USERNAME")"
}

unmount() {
    print_H2 "Attempting initial cleanup (in case of previous failure)..."
    umount -R /mnt 2>/dev/null || print_faint "Initial unmount of /mnt failed (likely already unmounted)."
    cryptsetup luksClose /dev/mapper/root 2>/dev/null || print_faint "Initial LUKS close failed (likely already closed)."
    print_success "Initial cleanup attempt finished."
}

post_install_instructions() {
    print_H1 "Post-Installation Instructions"

    print_H2 "1. Set Root Password (Optional but Recommended)"
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
    if [ "$ENABLE_ENCRYPTION" = true ]; then
        print_attention "Since encryption was used, close the LUKS container:"
        print_tip "cryptsetup luksClose /dev/mapper/root"
    fi
    print_tip "reboot"
}

# ==============================================================================
# === UTILITY FUNCTIONS ========================================================
# ==============================================================================

prompt_yes_no() {
    local prompt_text
    prompt_text="$(print_question "$1 "$G$E"y"$N$G"es"$N"/"$R$E"n"$N$R"o"$N": ")"
    while true; do
        read -p "$prompt_text" yn
        case $yn in
        [Yy]*) return 0 ;; 
        [Nn]*) return 1 ;; 
        *) print_attention "Please answer yes (y) or no (n)." ;; 
        esac
    done
}

# ==============================================================================
# === PARTITIONING =============================================================
# ==============================================================================

partition_disk() {
    print_H2 "Partitioning Disk: $DISK_PATH"
    print_faint "$(lsblk "$DISK_PATH")"

    if ! lsblk "$DISK_PATH" >/dev/null 2>&1; then
        fail "Disk $DISK_PATH not found."
    fi

    # Wipe existing signatures
    path_print=$(print_link "$DISK_PATH")
    print_H3 "Wiping existing filesystem signatures on $path_print..."
    prompt_yes_no "Wipe signatures on $path_print?" || fail "Declined to wipe signatures on $path_print."
    wipefs --all "$DISK_PATH" || print_warning "Failed to wipe signatures (maybe disk is clean?)"
    print_success "Wiped signatures on $path_print"

    print_H3 "Creating GPT partition table and partitions on $path_print..."
    prompt_yes_no "Partition $path_print using parted?" || fail "Declined to partition $path_print."

    print_H3 "Target Boot Partition: $(print_tip "$BOOT_PART")"
    print_H3 "Target Root Partition: $(print_tip "$ROOT_PART")"

    local parted_command="parted --script ${DISK_PATH} -- \
        mklabel gpt \
        mkpart ESP fat32 1MiB 1GiB \
        set 1 esp on \
        mkpart primary 1GiB 100% \
        print"

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

    # Verify partitions were created using the full path
    if ! lsblk "$BOOT_PART" >/dev/null 2>&1 || ! lsblk "$ROOT_PART" >/dev/null 2>&1; then
        print_faint "Final lsblk output for debugging:"
        print_faint "$(lsblk "$DISK_PATH")"
        fail "Boot ($BOOT_PART) or Root ($ROOT_PART) partition not found after running parted and udevadm settle."
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
        fail "Root partition $ROOT_PART not found before encryption setup."
    fi

    print_H3 "Formatting $ROOT_PART with LUKS2 (argon2id)..."
    print_attention "You will be prompted to enter and confirm a passphrase."
    local luks_format_command="cryptsetup luksFormat --type luks2 --pbkdf argon2id --pbkdf-memory 1048576 --iter-time 5000 ${ROOT_PART}"

    prompt_yes_no "Format $ROOT_PART with LUKS? This is DESTRUCTIVE." || fail "Declined LUKS formatting."
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
    mkfs.fat -F 32 -n BOOT "${BOOT_PART}" || fail "Failed to format boot partition."
    print_success "Boot partition formatted."

    # Root Partition (BTRFS)
    local root_device_print=$(print_link "$ROOT_DEVICE")
    print_H3 "Formatting Root device ($root_device_print) as BTRFS..."
    prompt_yes_no "Format $root_device_print as BTRFS?" || fail "Declined root partition formatting."
    mkfs.btrfs -L ROOT "$ROOT_DEVICE" || fail "Failed to format root partition ($ROOT_DEVICE)."
    print_success "Root partition formatted."

    print_finish "Filesystem formatting complete."
}

create_subvolumes() {
    print_H2 "Creating BTRFS Subvolumes"
    local btrfs_mount_opts="defaults,compress=zstd,noatime"
    local root_device_print=$(print_link "$ROOT_DEVICE")

    print_H3 "Mounting BTRFS root device ($root_device_print) temporarily..."
    mkdir -p /mnt
    mount -t btrfs -o "${btrfs_mount_opts}" "$ROOT_DEVICE" /mnt || fail "Failed to mount BTRFS root ($ROOT_DEVICE) temporarily."
    print_success "Temporary BTRFS mount successful."

    local subvolumes=("@" "@home" "@nix" "@snapshots" "@swap") 
    print_H3 "Creating subvolumes: $(print_link "${subvolumes[*]}")"
    for vol in "${subvolumes[@]}"; do
        local subvol_path="/mnt/${vol}"
        btrfs subvolume create "${subvol_path}" || fail "Failed to create subvolume ${vol}."
        print_success "Created subvolume ${vol}."
    done

    print_H3 "Unmounting temporary BTRFS root device..."
    umount /mnt || fail "Failed to unmount temporary BTRFS root."
    print_success "Temporary BTRFS unmount successful."

    print_finish "BTRFS subvolume creation complete."
}

mount_final_filesystems() {
    print_H2 "Mounting Final Filesystems"

    local btrfs_opts="defaults,compress=zstd,noatime,space_cache=v2,autodefrag"
    local root_mnt_opts="${btrfs_opts},subvol=@"
    local home_mnt_opts="${btrfs_opts},subvol=@home"
    local nix_mnt_opts="${btrfs_opts},subvol=@nix,nodev"
    local snapshots_mnt_opts="${btrfs_opts},subvol=@snapshots"
    local swap_mnt_opts="${btrfs_opts},subvol=@swap"
    local root_device_print=$(print_link "$ROOT_DEVICE")

    print_H3 "Mounting root subvolume (@) from $root_device_print to /mnt..."
    mount -o "${root_mnt_opts}" "$ROOT_DEVICE" /mnt || fail "Failed to mount root subvolume from $ROOT_DEVICE."
    print_success "Root subvolume mounted."

    local mount_points=("/mnt/boot" "/mnt/home" "/mnt/nix" "/mnt/.snapshots" "/mnt/.swap")
    print_H3 "Creating mount point directories: ${mount_points[*]}"
    mkdir -p "${mount_points[@]}" || fail "Failed to create mount point directories."
    print_success "Mount point directories created."

    print_H3 "Mounting other BTRFS subvolumes from $root_device_print..."
    mount -o "${home_mnt_opts}" "$ROOT_DEVICE" /mnt/home || fail "Failed to mount @home subvolume from $ROOT_DEVICE."
    mount -o "${nix_mnt_opts}" "$ROOT_DEVICE" /mnt/nix || fail "Failed to mount @nix subvolume from $ROOT_DEVICE."
    mount -o "${snapshots_mnt_opts}" "$ROOT_DEVICE" /mnt/.snapshots || fail "Failed to mount @snapshots subvolume from $ROOT_DEVICE."
    mount -o "${swap_mnt_opts}" "$ROOT_DEVICE" /mnt/.swap || fail "Failed to mount @swap subvolume from $ROOT_DEVICE."
    print_success "Other subvolumes mounted."

    print_H3 "Mounting Boot partition ($BOOT_PART) to /mnt/boot..."
    mount "$BOOT_PART" /mnt/boot || fail "Failed to mount boot partition."
    print_success "Boot partition mounted."

    print_finish "Final filesystems mounted."
}

# ==============================================================================
# === NIXOS INSTALLATION =======================================================
# ==============================================================================

setup_nixos_config() {
    print_H2 "Setting up NixOS Configuration Files"
    local nixos_config_dir="/mnt/etc/nixos" 
    local hardware_config_source="/mnt/etc/nixos/hardware-configuration.nix" 
    local temp_hardware_config_dest="/mnt/tmp/hardware-configuration.nix" 
    local final_hardware_config_dest="${REPO_DIR}/machines/${HOSTNAME}/hardware-configuration.nix"

    # 1. Generate hardware configuration
    print_H3 "Generating hardware-configuration.nix..."
    nixos-generate-config --root /mnt || fail "Failed to generate hardware configuration."
    if [ ! -f "$hardware_config_source" ]; then
        fail "hardware-configuration.nix not found after generation."
    fi
    print_success "hardware-configuration.nix generated."

    print_H3 "Temporarily moving hardware config to ${temp_hardware_config_dest}..."
    mkdir -p "$(dirname "$temp_hardware_config_dest")" || fail "Failed to create temporary directory /mnt/tmp."
    mv "$hardware_config_source" "$temp_hardware_config_dest" || fail "Failed to move hardware configuration to temporary location."
    print_success "Hardware configuration temporarily moved."

    print_H3 "Removing generated NixOS config directory ${nixos_config_dir} if it exists..."
    if [ -d "$nixos_config_dir" ]; then
        rm -rf "$nixos_config_dir" || fail "Failed to remove existing ${nixos_config_dir} directory."
        print_success "Removed existing ${nixos_config_dir}."
    else
        print_faint "Directory ${nixos_config_dir} did not exist, skipping removal."
    fi

    print_H3 "Cloning repository $REPO_URL to $REPO_DIR..."
    if ! command -v git &>/dev/null; then
        print_attention "git command not found. Attempting to install via nix-env..."
        nix-env -iA nixos.git || fail "Failed to install git. Cannot clone repository."
    fi
    if [ -d "$REPO_DIR" ]; then
      print_warning "Repository directory $REPO_DIR already exists. Removing..."
      rm -rf "$REPO_DIR" || fail "Failed to remove existing $REPO_DIR before cloning."
    fi
    git clone "$REPO_URL" "$REPO_DIR" || fail "Failed to clone repository into ${REPO_DIR}."
    print_success "Repository cloned."

    print_H3 "Checking out the 'minimal' branch..."
    git -C "$REPO_DIR" checkout minimal || fail "Failed to checkout 'minimal' branch."
    print_success "Checked out 'minimal' branch."

    print_H3 "Moving hardware config from temporary location to ${final_hardware_config_dest}..."
    mkdir -p "$(dirname "${final_hardware_config_dest}")" || fail "Failed to create machine directory in repo."
    if [ ! -f "$temp_hardware_config_dest" ]; then
        fail "Temporary hardware config $temp_hardware_config_dest not found!"
    fi
    mv "$temp_hardware_config_dest" "$final_hardware_config_dest" || fail "Failed to move hardware configuration to final destination."
    print_success "Hardware configuration moved to final location."

    print_H3 "Adding hardware configuration to Git index..."
    print_faint "Adding $REPO_DIR to git safe.directory config..."
    git config --global --add safe.directory "$REPO_DIR" || print_warning "Failed to add $REPO_DIR to git safe.directory."
    git -C "$REPO_DIR" config user.name "Vagari Installer" || print_warning "Failed to set git user.name"
    git -C "$REPO_DIR" config user.email "installer@vagari.local" || print_warning "Failed to set git user.email"
    git -C "$REPO_DIR" add -f "machines/${HOSTNAME}/hardware-configuration.nix" || fail "Failed to git add hardware configuration."
    git -C "$REPO_DIR" commit -m "Add generated hardware configuration for ${HOSTNAME}" --no-gpg-sign --author="Vagari Installer <installer@vagari.local>" || fail "Failed to git commit hardware configuration."
    print_success "Hardware configuration added and committed in Git."

    local machine_config_file="${REPO_DIR}/machines/${HOSTNAME}/configuration.nix"
    if [ ! -f "$machine_config_file" ]; then
        fail "Machine configuration file $machine_config_file not found! Was the repo cloned correctly and does the host profile exist?"
    fi

    if [ "$ENABLE_ENCRYPTION" = true ]; then
        local uuid_placeholder="YOUR-UUID"
        print_H3 "Injecting LUKS UUID ($ROOT_UUID) into ${machine_config_file} (replacing '$uuid_placeholder')..."
        if [[ -z "$ROOT_UUID" ]]; then
            fail "Invalid ROOT_UUID ($ROOT_UUID). Cannot inject into configuration when encryption is enabled."
        fi
        if ! grep -q "$uuid_placeholder" "$machine_config_file"; then
            if grep -q "$ROOT_UUID" "$machine_config_file"; then
                print_faint "LUKS UUID ($ROOT_UUID) seems to be already present in $machine_config_file. Skipping replacement."
            else
                # Check if the block is commented out from a previous run
                if grep -q "^#.*boot\.initrd\.luks\.devices" "$machine_config_file"; then
                     print_warning "LUKS config block seems commented out in $machine_config_file. Attempting to uncomment and inject UUID..."
                     # Uncomment first, then replace placeholder
                     sed -i '/^#.*boot\.initrd\.luks\.devices\."root" = {/,/};/s/^# *//' "$machine_config_file" || fail "Failed to uncomment LUKS block."
                     if ! grep -q "$uuid_placeholder" "$machine_config_file"; then
                        fail "Placeholder '$uuid_placeholder' still not found after uncommenting in $machine_config_file."
                     fi
                     sed -i "s|$uuid_placeholder|$ROOT_UUID|g" "$machine_config_file" || fail "Failed to inject LUKS UUID after uncommenting."
                     print_success "LUKS block uncommented and UUID injected."
                else
                    fail "Placeholder '$uuid_placeholder' not found in $machine_config_file, and the correct UUID ($ROOT_UUID) is also not present. Cannot inject required LUKS UUID."
                fi
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
    else
        # Encryption is disabled, ensure LUKS config is commented out
        print_H3 "Encryption disabled. Ensuring LUKS config is commented out in ${machine_config_file}..."
        # Use sed to comment out the block from the start pattern to the end pattern '};'
        sed -i '/boot\.initrd\.luks\.devices\."root" = {/,/};/s/^/# /' "$machine_config_file" || fail "Failed to comment out LUKS configuration block."
        if grep -q 'boot\.initrd\.luks\.devices\."root" = {' "$machine_config_file" && ! grep -q '^#.*boot\.initrd\.luks\.devices\."root" = {' "$machine_config_file"; then
             print_warning "LUKS config block might still be active after attempting to comment it out."
        else
             print_success "LUKS configuration block commented out successfully."
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

    prompt_yes_no "Ready to run nixos-install?" || fail "Declined to run nixos-install."

    print_H3 "Checking internet connection..."
    if ! ping -c 1 -W 5 8.8.8.8 &>/dev/null && ! ping -c 1 -W 5 1.1.1.1 &>/dev/null; then
        fail "No internet connection detected before NixOS install."
    fi
    print_success "Internet connection verified."

    print_H3 "Running nixos-install command..."
    nixos-install --show-trace --root /mnt --flake "$flake_path"

    print_finish "NixOS installation command completed."
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

    script_start
    check_root
    set_partitions

    unmount 

    if prompt_yes_no "Enable LUKS Encryption for root partition ($ROOT_PART)?"; then
        ENABLE_ENCRYPTION=true
        print_success "LUKS Encryption will be enabled."
    else
        ENABLE_ENCRYPTION=false
        print_warning "LUKS Encryption will be disabled."
    fi

    partition_disk

    if [ "$ENABLE_ENCRYPTION" = true ]; then
        setup_encryption
        ROOT_DEVICE="/dev/mapper/root"
        if [ ! -b "$ROOT_DEVICE" ]; then 
             fail "LUKS mapper device $ROOT_DEVICE not found after setup_encryption."
        fi
        print_success "Root device set to LUKS mapper: $(print_link "$ROOT_DEVICE")"
    else
        ROOT_DEVICE="$ROOT_PART" 
        if [ ! -b "$ROOT_DEVICE" ]; then 
             fail "Root partition device $ROOT_DEVICE not found."
        fi
        print_success "Root device set to raw partition: $(print_link "$ROOT_DEVICE")"
    fi

    format_filesystems
    create_subvolumes
    mount_final_filesystems
    setup_nixos_config
    install_nixos

    post_install_instructions

    exit 0 
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
