{
  name = "maintainers-iosched";
  knife = "test-maintainers";
  fixture = "nixpkgs-master-2026-09-12";
  files = [ "nixos/tests/iosched.nix" ];
  expectedCandidates = 1;
  expectedDiff = ../expected/maintainers-iosched.diff;
}
