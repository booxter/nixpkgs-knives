{
  name = "pkgs-lib-members";
  knife = "nixos-test-pkgs-lib";
  fixture = "nixpkgs-master-2026-09-12";
  files = [
    "nixos/tests/frr.nix"
    "nixos/tests/munin.nix"
    "nixos/tests/aria2.nix"
  ];
  expectedCandidates = 3;
  expectedDiff = ../expected/pkgs-lib-members.diff;
}
