{ pkgs, ... }: {
  programs.git = {
    enable = true;
    core.editor = "nvim";
  };
}
