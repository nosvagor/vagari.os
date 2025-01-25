{ 
  system.autoUpgrade = {
    enable = true;
    flake = "github:nosvagor/vagari.os";
    flags = [
      "--update-input" "nixpkgs"
      "--option" "build-use-sandbox" "true"
    ];
    dates = "04:00";
    randomizedDelaySec = "45min";
  };
} 