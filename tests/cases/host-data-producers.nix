{
  name = "host-data-producers";
  knife = "nixos-test-host-data";
  fixture = "nixpkgs-master-2026-09-12";
  files = [
    "nixos/tests/matrix/lk-jwt-service.nix"
    "nixos/tests/udisks2.nix"
    "nixos/tests/web-apps/dashy.nix"
  ];
  expectedCandidates = 3;
  expectedDiff = ../expected/host-data-producers.diff;
}
