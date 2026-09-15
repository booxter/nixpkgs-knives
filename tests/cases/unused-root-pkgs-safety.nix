{
  name = "unused-root-pkgs-safety";
  knife = "test-unused-root-pkgs";
  fixture = "nixpkgs-master-2026-09-12";
  files = [
    "nixos/tests/bees.nix"
    "nixos/tests/ente/generate-certs.nix"
    "nixos/tests/kerberos/ldap/default.nix"
  ];
  expectedCandidates = 0;
}
