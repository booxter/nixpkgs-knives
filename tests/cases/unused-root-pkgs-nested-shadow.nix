{
  name = "unused-root-pkgs-nested-shadow";
  knife = "nixos-test-unused-root-pkgs";
  fixture = "nixpkgs-master-2026-09-12";
  files = [ "nixos/tests/age-plugin-tpm-decrypt.nix" ];
  expectedCandidates = 1;
  expectedDiff = ../expected/unused-root-pkgs-nested-shadow.diff;
}
