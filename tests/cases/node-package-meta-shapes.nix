{
  name = "node-package-meta-shapes";
  knife = "test-node-package-meta";
  fixture = "nixpkgs-master-2026-09-12";
  files = [
    "nixos/tests/atuin-programs.nix"
    "nixos/tests/broadcast-box.nix"
    "nixos/tests/pulseaudio-tcp.nix"
  ];
  expectedCandidates = 3;
  expectedDiff = ../expected/node-package-meta-shapes.diff;
}
