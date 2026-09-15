{
  name = "node-package-meta-existing-config";
  knife = "test-node-package-meta";
  fixture = "nixpkgs-master-2026-09-12";
  files = [ "nixos/tests/omnom/default.nix" ];
  expectedCandidates = 1;
  expectedDiff = ../expected/node-package-meta-existing-config.diff;
}
