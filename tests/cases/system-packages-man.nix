{
  name = "system-packages-man";
  knife = "test-system-packages";
  fixture = "nixpkgs-master-2026-09-12";
  files = [ "nixos/tests/man.nix" ];
  expectedCandidates = 1;
  expectedDiff = ../expected/system-packages-man.diff;
}
