{
  name = "maintainers-quickwit";
  knife = "test-maintainers";
  fixture = "nixpkgs-master-2026-09-12";
  files = [ "nixos/tests/quickwit.nix" ];
  expectedCandidates = 1;
  expectedDiff = ../expected/maintainers-quickwit.diff;
}
