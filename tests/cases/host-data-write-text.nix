{
  name = "host-data-write-text";
  knife = "nixos-test-host-data";
  fixture = "nixpkgs-master-2026-09-12";
  files = [ "nixos/tests/headplane.nix" ];
  expectedCandidates = 1;
  expectedDiff = ../expected/host-data-write-text.diff;
}
