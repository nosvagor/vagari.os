{ pkgs, ... }: {
  programs.git = {
    enable = true;
    extraConfig = {
      init.defaultBranch = "master";
      core.editor = "nvim"; 
      pull.rebase = true;
    };
    aliases = {
      spp = "git stash; git pull; git stash pop";

      cm = "commit -m";

      br = "branch --sort=-committerdate"; 

      pf = "push --force-with-lease";

      l = "log --pretty=format:'%C(yellow)%h %Cblue%ad %Creset%s%Cgreen [%cn] %Cred%d' --date=short";
    };
    ignores = [ "*.swp" ".DS_Store" "vendor/" "node_modules/" "dist/" "build/" "*.log" "*.tmp" "*.temp" ]; 
  };
}