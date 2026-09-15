{
  name = "host-data-default-formal";
  knife = "test-host-data";
  fixture = "nixpkgs-master-2026-09-12";
  files = [ "nixos/tests/systemd-sysusers-password-option-override-ordering.nix" ];
  expectedCandidates = 1;
  expectedDiff = ../expected/host-data-default-formal.diff;
}
