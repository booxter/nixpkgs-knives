{
  name = "system-packages-zfs";
  knife = "nixos-test-system-packages";
  fixture = "nixpkgs-master-2026-09-12";
  files = [ "nixos/tests/zfs.nix" ];
  expectedCandidates = 0;
}
