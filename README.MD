# vagari.os
a personalized development environment, built using [Nix](https://nixos.org), inspired by the **vagari** philosophy

## Overview

**vagari.os** is my personal project to build a customized, modern Linux environment on top of NixOS.
The goal is to move beyond traditional “dotfiles” and create an **entire** portable OS configuration—covering:

- System-level setup
- User-level environment
- Setup for a “dynamic theming engine”
- Potentially an easy transition HPC/cloud expansion down the line

### Why Nix & Home Manager?
1. **Declarative & Reproducible**: A single source of truth for packages, services, and dotfiles, version-controlled for easy rollback.
2. **Modular Structure**: Each machine can have its own config, but share common modules (fonts, shells, etc.).
3. **Experimentation**: I want to learn NixOS.

---

## Machine Lineup

1. **`abbot-amd-nuc`**
   - Small, minimal-yet-powerful AMD NUC.
   - Hooks up to a monitor/keyboard for a portable desktop experience.

2. **`costello-desktop`**
   - Main workstation with a more powerful GPU, used for heavier workloads.

3. **`???-laptop`**
   - A future Linux laptop referencing *The Truth of Fact, the Truth of Feeling* protagonist (to be named).

4. **`???-cluster`**
   - Eventually, a cluster or HPC node referencing *Exhalation* main character or “robot” name.

---

## Software Choices & Rationale

Below is a summary of the core software and *why* I chose it.

### 1. **SDDM** (Login Manager)
  - **Why**: Provides a **nice, themable** login screen under Wayland, with better out-of-the-box visuals than minimal greeters.
  - **Plan**: Initially auto-login for dev convenience, later add multiple-user or theming.

### 2. **Hyprland** (Wayland Compositor)
  - **Why**: Modern tiling + dynamic window animations, very configurable.
  - **PipeWire** for audio is the default on recent NixOS setups; pairs well with Wayland.

### 3. **WezTerm** (Terminal Emulator)
- **Why**:
  - Excellent **font rendering** (ligatures, variable fonts, etc.).
  - Built-in splits/tabs can partially replace tmux or zellij.
  - GPU-accelerated, well-maintained.
  - **Persistence**: Currently leaning on WezTerm only. If I need fully persistent sessions (e.g., long-running remote tasks), I might add `tmux` or `zellij` later.

### 4. **Nushell** (Shell)
- **Why**:
  - Modern, structured data approach (tables & pipelines).
  - Never quite happy with zsh of fish.

### 5. **Neovim** (Editor)
- **Why**: Highly extensible with Lua.

### 6. **Firefox** (Browser)
- **Why**: Easy to customize with **userChrome.css** for deep theming.

### 7. **Btrfs + LUKS** (Filesystem & Encryption)
- **Why**:
  - Btrfs subvolumes let me do snapshots & potential rollbacks in synergy with Nix generations.
  - LUKS ensures full-disk encryption for security.

### 8. **Secrets Management**
- **Why**:
  - I want to move away from environment variables for API keys and credentials, aiming for a **declarative** approach.
  - Looking at tools like **[sops-nix](https://github.com/Mic92/sops-nix)** let me encrypt secrets in the repo.

### 9. **Fonts & Theming**
- **Why**:
  - I want a single **variable font** with ligatures, e.g., [Iosevka](https://typeof.net/Iosevka/).
  - A **unified color palette** under “vagari,” which can shift over time.
- **Plan**: Create an package that modifies color definitions across WezTerm, Neovim, Hyprland, etc., to allow for dynamic changes theming.

---

## Repo Structure

```plaintext
vagari.os/
├── flake.nix
├── flake.lock           # Nix automatically generates this
├── machines
│   ├── abbot-amd-nuc
│   │   ├── configuration.nix
│   │   └── hardware-configuration.nix
│   ├── costello-desktop
│   │   ├── configuration.nix
│   │   └── hardware-configuration.nix
│   ├── ???-laptop
│   └── ???-cluster
├── home
│   ├── default.nix      # Main Home Manager entry point
│   └── modules          # Each program gets its own file
│       ├── nushell.nix
│       ├── wezterm.nix
│       ├── neovim.nix
│       ├── firefox.nix
│       └── fonts.nix
├── themes
│   └── vagari-colors.nix
├── overlays             # If I do custom package overlays
└── README.md            # You are here


Installation & Usage
Install NixOS as usual. During installation, run nixos-generate-config to generate the base hardware-configuration.nix.

Clone this repo onto the new system:

bash```
Copy code
git clone https://github.com/nosvagor/vagari.os.git
cd vagari.os
```
Switch to your machine config:

bash```
Copy code
sudo nixos-rebuild switch --flake .#machine-name
```

Activate your user environment (Home Manager):

bash```
Copy code
home-manager switch --flake .#user-name
```

or

bash```
Copy code
nix run .#homeConfigurations.user-name.activationPackage
```
