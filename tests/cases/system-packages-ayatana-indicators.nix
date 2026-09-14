{
  name = "system-packages-ayatana-indicators";
  knife = "nixos-test-system-packages";
  fixture = "nixpkgs-master-2026-09-12";
  files = [ "nixos/tests/ayatana-indicators.nix" ];
  expectedCandidates = 0;
}
