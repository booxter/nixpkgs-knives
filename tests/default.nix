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
    ./cases/system-packages-ayatana-indicators.nix
    ./cases/system-packages-ax25.nix
    ./cases/system-packages-man.nix
  ];
in
builtins.listToAttrs (
  map (case: {
    inherit (case) name;
    value = runKnife (case // { fixture = fixtures.${case.fixture}; });
  }) cases
)
