{
  name = "system-packages-ax25";
  knife = "test-system-packages";
  fixture = "nixpkgs-master-2026-09-12";
  files = [ "nixos/tests/ax25.nix" ];
  expectedCandidates = 1;
  expectedDiff = ../expected/system-packages-ax25.diff;
}
