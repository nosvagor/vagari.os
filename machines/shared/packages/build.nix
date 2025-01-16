# ██████╗ ██╗   ██╗██╗██╗     ██████╗ 
# ██╔══██╗██║   ██║██║██║     ██╔══██╗
# ██████╔╝██║   ██║██║██║     ██║  ██║
# ██╔══██╗██║   ██║██║██║     ██║  ██║
# ██████╔╝╚██████╔╝██║███████╗██████╔╝
# ╚═════╝  ╚═════╝ ╚═╝╚══════╝╚═════╝ 
# Development and build tools.
# Compiler toolchains, build utilities, and development tools.

{ pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    # Modern Build Tools
    just            # Modern make alternative
    ninja           # Fast build system
    meson           # Modern build system
    sccache         # Compiler cache
    
    # Core Compilers & Tools
    gcc             # GNU C/C++
    clang           # LLVM C/C++
    lldb            # LLVM debugger
    gdb             # GNU debugger
    
    # Build Essentials
    gnumake         # GNU make
    cmake           # CMake build
    pkg-config      # Library helper
    
    # Development Tools
    hyperfine       # Benchmarking
    tokei           # Code statistics
    difftastic      # Modern diff
    delta           # Git diff viewer
    
    # Version Control
    gh              # GitHub CLI
    git-lfs         # Large file support
    lazygit         # Git TUI
    
    # Container Tools
    docker          # Container runtime
    docker-compose  # Container orchestration
    lazydocker      # Docker TUI

  ];
}