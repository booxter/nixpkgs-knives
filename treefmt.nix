{
  projectRootFile = "flake.nix";

  programs.nixfmt.enable = true;

  programs.shellcheck = {
    enable = true;
    external-sources = true;
    includes = [
      "*.sh"
      "cut"
      "groups/*/bin/*"
      "groups/*/verify"
      "verify"
    ];
    source-path = "SCRIPTDIR";
  };
}
