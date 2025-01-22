# vagari.os

A personalized development environment, built using [Nix](https://nixos.org), inspired by the [vagari](https://github.com/nosvagor/vagari) philosophy.

## Overview

**vagari.os** is my personal project to build a customized, modern Linux environment on top of NixOS.
The goal is to move beyond traditional "dotfiles" and create an **entire** portable OS configuration. No IDE. Instead, the entire system is an personal development environment.

## Project Structure

```plaintext
vagari.os/
├── flake.nix             # main entry point
├── machines/             # system configurations
│   ├── shared/           # shared system settings
│   │   ├── core.nix      # core (boot, hardware, services, users) settings
│   │   ├── fonts.nix
│   │   └── packages/     # base packages, organized by purpose
│   │   │   ├── base.nix
│   │   │   ├── build.nix
│   │   │   ├── create.nix
│   │   │   └── game.nix
│   │   ├── abbot/            # portable AMD NUC config
│   │   └── costello/         # full workstation config
│   └── home/
│       ├── modules/          # app configs
│       │   ├── hyprland.nix
│       │   ├── ghostty.nix
│       │   ├── neovim.nix
│       │   ├── browser.nix
│       │   └── ...
│       ├── abbot.nix         # AMD NUC home config
│       └── costello.nix      # full Workstation home config
```

## Software Stack

<details>
<summary>🖥️ <b>Core System</b></summary>
<br>

**Display Server**: [Wayland](https://wayland.freedesktop.org/)

- Modern, secure display protocol
- Better HiDPI support
- Hardware acceleration

**Window Manager**: [Hyprland](https://hyprland.org/)

- Dynamic tiling Wayland compositor
- GPU-accelerated animations
- Modern features like blur and rounded corners
- Custom workspace layout (SEDT-based)

**Display Manager**: [SDDM](https://github.com/sddm/sddm)

- Fast, modern login manager
- Wayland support
- Themed with Catppuccin

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

- Used primarily as status Bar
- Custom widgets for anything else that is needed.

<br>
</details>

<details open>
<summary>📱 <b>Core Applications</b></summary>
<br>

**Terminal**: [Ghostty](https://github.com/mitchellh/ghostty)

- GPU-accelerated terminal emulator
- Modern features like ligatures
- Excellent font rendering

**Browser**: [Firefox Developer Edition](https://www.mozilla.org/en-US/firefox/developer/)

- Custom privacy settings
- Development tools enabled
- Nordic theme integration
- Additional browsers for testing:
  - Chrome, Edge, Brave

**Editor**: [Neovim](https://neovim.io/)

- Modal editing
- LSP integration
- Custom configuration

<br>
</details>

<details>
<summary>🔧 <b>Utilities</b></summary>
<br>

**Build Tools**:

- [`just`](https://github.com/casey/just): Modern Make alternative
- [`ninja`](https://ninja-build.org/)/[`meson`](https://mesonbuild.com/): Fast build system
- [`sccache`](https://github.com/mozilla/sccache): Compiler cache

**Modern CLI Tools**:

- [`eza`](https://github.com/eza-community/eza): Modern ls
- [`bat`](https://github.com/sharkdp/bat): Modern cat
- [`fd`](https://github.com/sharkdp/fd): Modern find
- [`ripgrep`](https://github.com/BurntSushi/ripgrep): Modern grep
- [`du-dust`](https://github.com/bootandy/dust): Modern du
- [`btop`](https://github.com/aristocratos/btop): System monitor
- [`zoxide`](https://github.com/ajeetdsouza/zoxide): Smart cd

**Network Tools**:

- [`age`](https://github.com/FiloSottile/age): Modern encryption
- [`dogdns`](https://github.com/ogham/dog): Modern dig
- [`mtr`](https://github.com/traviscross/mtr): Modern traceroute
- [`socat`](http://www.dest-unreach.org/socat/): Modern netcat

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
   curl -L -O https://channels.nixos.org/nixos-23.11/latest-nixos-minimal-x86_64-linux.iso
   ```

2. Create bootable USB:

   ```bash
   # List available drives
   lsblk

   # Write ISO to USB drive (replace sdX with your USB drive)
   sudo dd if=nixos-minimal.iso of=/dev/sdX bs=4M status=progress
   ```

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

<details>
<summary>🚀 <b>2. Run Installation</b></summary>
<br>

```bash
# Download and run installer in one command
sh <(curl -L https://raw.githubusercontent.com/nosvagor/vagari.os/master/install.sh)

# Options                  (changes defaults in install.sh):
# --hostname <hostname>    (default: abbot)
# --disk <disk>            (default: /dev/nvme0n1)
# --username <username>    (default: nosvagor)
# --help
```

The script will:

- Set up LUKS encryption (you'll be prompted for a passphrase)
- Create BTRFS filesystem with subvolumes (@, @home, @nix, @snapshots)
- Enable compression and other optimizations
- Install base NixOS system

<br>
</details>

<details>
<summary>🔐 <b>3. Post-Install Setup</b></summary>
<br>

After installation and first boot:

```bash
# Set up secrets
bw login
bw get notes sops-keys > ~/.config/sops/age/vagari-os.txt

# Apply your configuration
cd /etc/nixos/vagari.os
sudo nixos-rebuild switch --flake .#$(hostname)
```

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
<summary>📝 <b>Version Control</b></summary>
<br>

**Atomic Changes**:

```bash
# Stage specific module changes
git add home/modules/neovim.nix
git commit -m "neovim: add telescope plugin"

# Or stage all config changes
git add .
git commit -m "system: update core packages"
```

**Feature Branches**:

```bash
# Create feature branch
git checkout -b feature/wayland-setup

# Test and commit changes
sudo nixos-rebuild build --flake .#$(hostname)
git add .
git commit -m "wayland: add hyprland configuration"

# Merge when ready
git checkout main
git merge feature/wayland-setup
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
