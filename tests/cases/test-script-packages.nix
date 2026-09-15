{
  name = "test-script-packages";
  knife = "test-test-script-packages";
  fixture = "nixpkgs-master-2026-09-12";
  files = [
    "nixos/tests/activation/nixos-init.nix"
    "nixos/tests/ghostunnel.nix"
    "nixos/tests/3proxy.nix"
  ];
  expectedCandidates = 2;
  expectedDiff = ../expected/test-script-packages.diff;
}
