{
  name = "node-config-packages-direct";
  knife = "nixos-test-node-config-packages";
  fixture = "nixpkgs-master-2026-09-12";
  files = [
    "nixos/tests/cloudlog.nix"
    "nixos/tests/btrbk.nix"
  ];
  expectedCandidates = 2;
  expectedDiff = ../expected/node-config-packages-direct.diff;
}
