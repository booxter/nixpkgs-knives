{
  name = "unused-root-pkgs-clickhouse-ui";
  knife = "nixos-test-unused-root-pkgs";
  fixture = "nixpkgs-master-2026-09-12";
  files = [ "nixos/tests/clickhouse/ui.nix" ];
  expectedCandidates = 1;
  expectedDiff = ../expected/unused-root-pkgs-clickhouse-ui.diff;
}
