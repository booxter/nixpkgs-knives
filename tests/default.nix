{
  pkgs,
  cut,
  fixtures,
}:

let
  runKnife = pkgs.callPackage ./run-with-knife.nix { inherit cut; };
  cases = map import [
    ./cases/maintainers-airsonic.nix
    ./cases/maintainers-iosched.nix
    ./cases/maintainers-quickwit.nix
    ./cases/system-packages-ayatana-indicators.nix
    ./cases/system-packages-ax25.nix
    ./cases/system-packages-man.nix
    ./cases/system-packages-snapcast.nix
    ./cases/system-packages-zfs.nix
  ];
in
builtins.listToAttrs (
  map (case: {
    inherit (case) name;
    value = runKnife (case // { fixture = fixtures.${case.fixture}; });
  }) cases
)
