{
  name = "pkgs-lib-scope-and-safety";
  knife = "test-pkgs-lib";
  fixture = "nixpkgs-master-2026-09-12";
  files = [
    "nixos/tests/drbd.nix"
    "nixos/tests/ferm.nix"
    "nixos/tests/android-translation-layer.nix"
  ];
  expectedCandidates = 3;
  expectedDiff = ../expected/pkgs-lib-scope-and-safety.diff;
}
