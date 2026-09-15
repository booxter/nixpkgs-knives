{
  name = "system-packages-snapcast";
  knife = "test-system-packages";
  fixture = "nixpkgs-master-2026-09-12";
  files = [ "nixos/tests/snapcast.nix" ];
  expectedCandidates = 1;
  expectedDiff = ../expected/system-packages-snapcast.diff;
}
