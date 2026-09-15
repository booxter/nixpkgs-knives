{
  name = "system-packages-zfs";
  knife = "test-system-packages";
  fixture = "nixpkgs-master-2026-09-12";
  files = [ "nixos/tests/zfs.nix" ];
  expectedCandidates = 0;
}
