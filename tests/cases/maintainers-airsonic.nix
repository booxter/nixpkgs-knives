{
  name = "maintainers-airsonic";
  knife = "nixos-test-maintainers";
  fixture = "nixpkgs-master-2026-09-12";
  files = [ "nixos/tests/airsonic.nix" ];
  expectedCandidates = 1;
  expectedDiff = ../expected/maintainers-airsonic.diff;
}
