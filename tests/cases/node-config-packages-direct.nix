{
  name = "node-config-packages-direct";
  knife = "test-node-config-packages";
  fixture = "nixpkgs-master-2026-09-12";
  files = [
    "nixos/tests/cloudlog.nix"
    "nixos/tests/btrbk.nix"
    "nixos/tests/userborn-subids-immutable-etc.nix"
  ];
  expectedCandidates = 3;
  expectedDiff = ../expected/node-config-packages-direct.diff;
}
