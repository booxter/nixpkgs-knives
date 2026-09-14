{
  cut,
  diffutils,
  gitMinimal,
  runCommand,
  writeShellScript,
}:

let
  fakeEvalJobs = writeShellScript "fake-nix-eval-jobs" ''
    set -euo pipefail

    mode=
    snapshot=
    while (( $# > 0 )); do
      case "$1" in
        --argstr)
          case "$2" in
            mode) mode="$3" ;;
            nixpkgsPath) snapshot="$3" ;;
          esac
          shift 3
          ;;
        --gc-roots-dir | --workers)
          shift 2
          ;;
        --force-recurse | --quiet)
          shift
          ;;
        *)
          shift
          ;;
      esac
    done

    IFS= read -r contents < "$snapshot/nixos/tests/example.nix"
    if [[ "$contents" == new ]]; then
      modified=true
    else
      modified=false
    fi

    if [[ "$modified" == false ]]; then
      echo '{"attr":"changed.__job","drvPath":"/nix/store/before-test.drv"}'
      echo '{"attr":"removed.__job","drvPath":"/nix/store/removed-test.drv"}'
      echo '{"attr":"unchanged.__job","drvPath":"/nix/store/unchanged-test.drv"}'
    elif [[ "''${VERIFY_FAKE_ERROR:-false}" == true ]]; then
      echo '{"attr":"changed","error":"modified evaluation failed"}'
      echo '{"attr":"unchanged.__job","drvPath":"/nix/store/unchanged-test.drv"}'
    elif [[ "$mode" == driver ]]; then
      echo '{"attr":"changed.__job","drvPath":"/nix/store/changed-driver.drv"}'
      echo '{"attr":"new.__job","drvPath":"/nix/store/new-driver.drv"}'
      echo '{"attr":"unchanged.__job","drvPath":"/nix/store/unchanged-driver.drv"}'
    else
      echo '{"attr":"changed.__job","drvPath":"/nix/store/changed-test.drv"}'
      echo '{"attr":"new.__job","drvPath":"/nix/store/new-test.drv"}'
      echo '{"attr":"unchanged.__job","drvPath":"/nix/store/unchanged-test.drv"}'
    fi
  '';

  fakeStore = writeShellScript "fake-nix-store" ''
    printf '%s\n' "$*" >> "$VERIFY_TEST_LOG"
  '';
in
runCommand "test-nixos-test-verifier"
  {
    nativeBuildInputs = [
      diffutils
      gitMinimal
    ];
  }
  ''
    set -euo pipefail

    mkdir -p repo/nixos/tests
    cd repo
    git init -q
    git config user.email test@example.invalid
    git config user.name Test
    printf 'old\n' > nixos/tests/example.nix
    git add nixos/tests/example.nix
    git commit -qm initial
    printf 'new\n' > nixos/tests/example.nix

    export NIXPKGS_KNIVES_NIX_EVAL_JOBS=${fakeEvalJobs}
    export NIXPKGS_KNIVES_NIX_STORE=${fakeStore}
    export VERIFY_TEST_LOG="$PWD/store.log"

    ${cut}/bin/verify --system x86_64-linux > verify.log
    diff -u ${./expected/verifier.log} verify.log
    diff -u ${./expected/verifier-store.log} "$VERIFY_TEST_LOG"

    : > "$VERIFY_TEST_LOG"
    ${cut}/bin/verify --list --system x86_64-linux > list.log
    diff -u ${./expected/verifier-list.log} list.log
    test ! -s "$VERIFY_TEST_LOG"

    export VERIFY_FAKE_ERROR=true
    if ${cut}/bin/verify --list --system x86_64-linux > error.log 2>&1; then
      echo 'verify unexpectedly accepted a new evaluation error' >&2
      exit 1
    fi

    touch "$out"
  ''
