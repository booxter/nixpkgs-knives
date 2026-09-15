{
  name = "node-config-packages-local-pkgs";
  knife = "test-node-config-packages";
  fixture = "nixpkgs-master-2026-09-12";
  files = [ "nixos/tests/acme/caddy.nix" ];
  expectedCandidates = 1;
  expectedDiff = ../expected/node-config-packages-local-pkgs.diff;
}
