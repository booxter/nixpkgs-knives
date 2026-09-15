{
  name = "host-data-scope-and-safety";
  knife = "test-host-data";
  fixture = "nixpkgs-master-2026-09-12";
  files = [
    "nixos/tests/containers-imperative.nix"
    "nixos/tests/amazon-cloudwatch-agent.nix"
  ];
  expectedCandidates = 2;
  expectedDiff = ../expected/host-data-scope-and-safety.diff;
}
