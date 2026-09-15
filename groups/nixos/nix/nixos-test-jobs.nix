{
  mode,
  nixpkgsPath,
  system,
}:

let
  pkgs = import (builtins.toPath nixpkgsPath) { inherit system; };
  callTest = import ./select-nixos-test-job.nix { inherit mode; };
in
# Delegate discovery to Nixpkgs. In particular, it knows how to instantiate
# legacy function tests without mistaking arbitrary attribute sets for groups.
import (builtins.toPath "${nixpkgsPath}/nixos/tests/all-tests.nix") {
  inherit callTest pkgs system;
}
