{
  name = "host-data-scope-and-safety";
  knife = "test-host-data";
  fixture = "nixpkgs-master-2026-09-12";
  files = [
    "nixos/tests/containers-imperative.nix"
    "nixos/tests/amazon-cloudwatch-agent.nix"
    "nixos/tests/etcd/multi-node.nix"
  ];
  expectedCandidates = 3;
  expectedDiff = ../expected/host-data-scope-and-safety.diff;
}
