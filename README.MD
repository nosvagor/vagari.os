# vagari.os

A personalized development environment, built using [Nix](https://nixos.org), inspired by the [vagari](https://github.com/nosvagor/vagari) philosophy.

## Overview

**vagari.os** is my personal project to build a customized, modern Linux environment on top of NixOS.
The goal is to move beyond traditional "dotfiles" and create an **entire** portable OS configuration. No IDE. Instead, the entire system is an personal development environment.

## Project Structure

```plaintext
vagari.os/
├── flake.nix # Main entry point
├── machines/             # System configurations
│   ├── shared/           # Shared system settings
│   │   ├── core.nix      # Core (boot, hardware, services, users) settings
│   │   ├── fonts.nix
│   │   └── packages/     # base packages, organized by purpose
│   │   │   ├── base.nix
│   │   │   ├── build.nix
│   │   │   ├── create.nix
│   │   │   └── game.nix
│   ├── abbot/            # portable AMD NUC config
│   └── costello/         # full workstation config
└── home/
    ├── modules/          # app configs
    │   ├── hyprland.nix
    │   ├── ghostty.nix
    │   ├── neovim.nix
    │   ├── browser.nix
    │   └── ...
    ├── abbot.nix         # AMD NUC home config
    └── costello.nix      # Full Workstation home config
```

## Core Software Stack

### System Level

- **SDDM**: Modern Wayland login manager
- **Hyprland**: Tiling Wayland compositor
- **PipeWire**: Modern audio system

### User Level

- **Ghostty**: Modern GPU-accelerated terminal
- **Nushell**: Structured shell
- **Neovim**: Primary editor
- **Firefox**: Primary browser

## Machine Lineup

1. **`abbot`** (AMD NUC)

   - Minimal yet powerful portable setup
   - Development focused configuration

2. **`costello`** (Workstation)
   - Full-featured desktop
   - Content creation & gaming capable

## Usage

1. Install NixOS and clone this repo:

```bash
git clone https://github.com/nosvagor/vagari.os.git
cd vagari.os
```

2. Build system configuration:

```bash
sudo nixos-rebuild switch --flake .#machine-name
```

3. Build user configuration:

```bash
home-manager switch --flake .#nosvagor-machine-name
```
