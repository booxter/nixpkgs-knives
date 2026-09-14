{
  pkgs,
  cut,
  fixtures,
}:

let
  runKnife = pkgs.callPackage ./run-with-knife.nix { inherit cut; };
  ruleTests = pkgs.runCommand "test-ast-grep-rules" { nativeBuildInputs = [ pkgs.ast-grep ]; } ''
    cp -R ${../ast-grep} ast-grep
    chmod -R u+w ast-grep
    cd ast-grep
    ast-grep test --skip-snapshot-tests
    touch "$out"
  '';
  cases = map import [
    ./cases/maintainers-airsonic.nix
    ./cases/maintainers-iosched.nix
    ./cases/maintainers-quickwit.nix
    ./cases/host-data-default-formal.nix
    ./cases/host-data-producers.nix
    ./cases/host-data-scope-and-safety.nix
    ./cases/host-data-write-text.nix
    ./cases/node-config-packages-direct.nix
    ./cases/node-config-packages-local-pkgs.nix
    ./cases/node-package-meta-existing-config.nix
    ./cases/node-package-meta-scope-and-safety.nix
    ./cases/node-package-meta-shapes.nix
    ./cases/pkgs-lib-members.nix
    ./cases/pkgs-lib-scope-and-safety.nix
    ./cases/system-packages-ayatana-indicators.nix
    ./cases/system-packages-ax25.nix
    ./cases/system-packages-man.nix
    ./cases/system-packages-snapcast.nix
    ./cases/system-packages-zfs.nix
    ./cases/unused-root-pkgs-clickhouse-ui.nix
    ./cases/unused-root-pkgs-nested-shadow.nix
    ./cases/unused-root-pkgs-safety.nix
  ];
in
{
  ast-grep-rules = ruleTests;
  cut-dispatcher = pkgs.callPackage ./cut.nix { };
}
// builtins.listToAttrs (
  map (case: {
    inherit (case) name;
    value = runKnife (case // { fixture = fixtures.${case.fixture}; });
  }) cases
)
