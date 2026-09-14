{
  name = "node-package-meta-scope-and-safety";
  knife = "nixos-test-node-package-meta";
  fixture = "nixpkgs-master-2026-09-12";
  files = [
    "nixos/tests/bcachefs.nix"
    "nixos/tests/ringboard.nix"
  ];
  expectedCandidates = 1;
  expectedDiff = ../expected/node-package-meta-scope-and-safety.diff;
}
