# vagari.os

A personalized development environment, built using [Nix](https://nixos.org), inspired by the [vagari](https://github.com/nosvagor/vagari) philosophy.

## Overview

**vagari.os** is my personal project to build a customized, modern Linux environment on top of NixOS.
The goal is to move beyond traditional "dotfiles" and create an **entire** portable OS configuration.

## Software Stack

<details>
<summary>🖥️ <b>Core System</b></summary>
<br>

**Display Server**: [Wayland](https://wayland.freedesktop.org/)

**Window Manager**: [Hyprland](https://hyprland.org/)

**Display Manager**: [SDDM](https://github.com/sddm/sddm)

</details>

<details>
<summary>🎨 <b>User Interface</b></summary>
<br>

**Theme**: [Nordic](https://github.com/EliverLara/Nordic)

- Cohesive dark theme across GTK and Qt
- Nordzy cursor and icon themes
- Consistent styling across all applications

**Fonts**:

- UI Fonts:

  - [Satoshi](https://www.fontshare.com/fonts/satoshi): Primary UI font, geometric variable sans-serif
  - [Outfit](https://github.com/Outfitio/Outfit-Fonts): Modern display font for headings

- Code Font:

  - [Iosevka Custom Build](https://typeof.net/Iosevka/customizer): "Iosevka Vagari"
    - Customized for coding clarity
    - PureScript-style ligatures
    - Enhanced character variants for readability
    - Normal spacing for UI compatibility

- Reading & Print:

  - [EB Garamond](https://github.com/octaviopardo/EBGaramond12): Classic serif for long-form text
  - [Crimson](https://github.com/skosch/Crimson): Modern serif alternative

- Extended Support:

  - Noto family for Unicode, CJK, emoji, and more
  - Math & science symbols via STIX Two
  - Comprehensive script coverage (Arabic, Hebrew, Indic)

**Widgets**: [Eww](https://github.com/elkowar/eww)

<br>
</details>

<details open>
<summary>📱 <b>Core Applications</b></summary>
<br>

**Terminal**: [Kitty]()

**Browser**: [Firefox Developer Edition](https://www.mozilla.org/en-US/firefox/developer/)

**Editor**: [Neovim](https://neovim.io/)

<br>
</details>

<details>
<summary>🎥 <b>Content Creation</b></summary>
<br>

**Video**:

- [OBS Studio](https://obsproject.com/): Video recording and streaming
- [DaVinci Resolve](https://www.blackmagicdesign.com/products/davinciresolve): Video editing
- [FFmpeg](https://ffmpeg.org/): it's ffmpeg

**3D/Graphics**:

- [Blender](https://www.blender.org/): 3D modeling, animation, and rendering
- [GIMP](https://www.gimp.org/): Image editing
- [Inkscape](https://inkscape.org/): Vector graphics

**Audio**:

- [Ardour](https://ardour.org/): Audio recording and editing
- [Audacity](https://www.audacityteam.org/): Audio editing

<br>
</details>

## Installation

<details>
<summary>💿 <b>1. Boot NixOS Installer</b></summary>
<br>

1. Download the [NixOS minimal ISO](https://nixos.org/download.html)

   ```bash
   # Download latest minimal ISO
   curl -L -O https://channels.nixos.org/nixos-24.11/latest-nixos-minimal-x86_64-linux.iso
   ```

2. Create bootable USB:

   ```bash
   # List available drives
   lsblk

   # Write ISO to USB drive (replace sdX with your USB drive)
   sudo dd if=nixos-minimal.iso of=/dev/sdX bs=4M status=progressvu   ```

3. Boot from USB and connect to internet if needed:
   ```bash
   # For WiFi
   sudo systemctl start wpa_supplicant
   wpa_cli
   > add_network
   > set_network 0 ssid "your_ssid"
   > set_network 0 psk "your_password"
   > enable_network 0
   > quit
   ```

</details>

<details open>
<summary>🚀 <b>2. Run Installation</b></summary>
<br>

```bash
# Download, make executable, and run installer in one command
curl -Lsfo install.sh https://raw.githubusercontent.com/nosvagor/vagari.os/master/install.sh
chmod +x install.sh
sudo -i
./install.sh
```

**Replace placeholders:**

- `<DISK_DEVICE>`: Target disk device name (e.g., `nvme0n1`, `sda`). **Do not include `/dev/`**.
- `<HOSTNAME>`: Desired hostname (must match a machine in the flake, e.g., `abbot`).
- `<USERNAME>`: Primary username for the system (e.g., `nosvagor`).

**Other Options:**

- `--post-install`: Show only the post-installation instructions.
- `--dry-run`: Simulate the installation wito0798gbesttgbetgbetgbgiesthout making changes.
- `--help`: Display help message.

The script will:

- Set up LUKS encryption (you'll be prompted for a passphrase).
- Create BTRFS filesystem with subvolumes (`@`, `@home`, `@nix`, `@snapshots`, `@swap`).
- Clone the configuration repository.
- Inject necessary configuration (LUKS UUID).
- Install base NixOS system using the flake.
- Prompt you to set the password for `<USERNAME>`.

<br>
</details>

<details>
<summary>🔐 <b>3. Post-Install Setup (Manual Steps)</b></summary>
<br>

After the script finishes, you **must** perform these steps **before** rebooting:

1.  **Set Root Password:**

    ```bash
    # Enter the new system environment
    nixos-enter --root /mnt

    # Inside the environment, set the root password
    passwd root

    # Exit the environment
    exit
    ```

2.  **Place SOPS Key:**

    ```bash
    # Ensure /mnt is still mounted
    # Retrieve your SOPS key (e.g., using Bitwarden CLI)
    bw get item sops-key --raw > /mnt/etc/sops/key.txt

    # Set correct permissions (use nixos-enter again)
    nixos-enter --root /mnt -c 'chmod 600 /etc/sops/key.txt'
    ```

3.  **Unmount and Reboot:**

    ```bash
    # Unmount all partitions
    umount -R /mnt

    # Reboot into your new system
    reboot
    ```

_(You can view these instructions again anytime by running `./install.sh --post-install` from the installer environment)_

</details>

## Development Workflow

<details open>
<summary>🔄 <b>Customizing Modules</b></summary>
<br>

**Testing Changes**:

```bash
# Validate flake
nix flake check

# Build without applying
sudo nixos-rebuild build --flake .#$(hostname)
```

**Applying Changes**:

```bash
# Quick rebuild (only rebuild changed modules)
sudo nixos-rebuild switch --flake .#$(hostname) --fast

# Full rebuild (useful after major changes)
sudo nixos-rebuild switch --flake .#$(hostname)
```

**Debugging**:

```bash
# Show detailed build logs
sudo nixos-rebuild switch --flake .#$(hostname) --show-trace

# Print dependency graph
sudo nixos-rebuild switch --flake .#$(hostname) --print-build-logs
```

<br>
</details>

<details>
<summary>💡 <b>Development Tips</b></summary>
<br>

**Module Organization**:

- Keep machine-specific configs in `machines/<hostname>/`
- Share common settings in `machines/shared/`
- User-specific configs go in `home/modules/`

**Example Workflow**:

```bash
# 1. Edit a module
nvim home/modules/neovim.nix

# 2. Test changes
sudo nixos-rebuild build --flake .#$(hostname)

# 3. Apply if build succeeds
sudo nixos-rebuild switch --flake .#$(hostname) --fast
```

<br>
</details>

<details>
<summary>🔨 <b>Common Patterns</b></summary>
<br>

**Testing in Temporary Shell**:

```bash
# Try new packages
nix-shell -p package-name

# Or use flake-based dev shell
nix develop
```

**System Recovery**:

```bash
# List generations
sudo nix-env --list-generations --profile /nix/var/nix/profiles/system

# Roll back to last working config
sudo nixos-rebuild switch --rollback
```

**Updating Dependencies**:

```bash
# Update all inputs
nix flake update

# Update specific input
nix flake lock --update-input nixpkgs
```

<br>
</details>
