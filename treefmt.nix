{
  projectRootFile = "flake.nix";

  programs.nixfmt.enable = true;

  programs.shellcheck = {
    enable = true;
    external-sources = true;
    includes = [
      "*.sh"
      "bin/*"
      "cut"
    ];
    source-path = "SCRIPTDIR";
  };
}
