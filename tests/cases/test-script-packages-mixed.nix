{
  name = "test-script-packages-mixed";
  knife = "nixos-test-test-script-packages";
  fixture = "local";
  files = [ "nixos/tests/test-script-packages-mixed.nix" ];
  expectedCandidates = 0;
}
