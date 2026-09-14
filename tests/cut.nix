{
  bash,
  diffutils,
  runCommand,
  writeShellScript,
}:

let
  alpha = writeShellScript "alpha" ''
    printf 'alpha\n' >> "$CUT_TEST_LOG"
  '';
  zeta = writeShellScript "zeta" ''
    printf 'zeta\n' >> "$CUT_TEST_LOG"
  '';
  early = writeShellScript "early" ''
    printf 'early\n' >> "$CUT_TEST_LOG"
    if [[ -e "$CUT_TEST_STATE/unlocked" && ! -e "$CUT_TEST_STATE/done" ]]; then
      touch "$CUT_TEST_STATE/done" "$NIXPKGS_KNIVES_CHANGED_FILE"
    fi
  '';
  late = writeShellScript "late" ''
    printf 'late\n' >> "$CUT_TEST_LOG"
    if [[ ! -e "$CUT_TEST_STATE/unlocked" ]]; then
      touch "$CUT_TEST_STATE/unlocked" "$NIXPKGS_KNIVES_CHANGED_FILE"
    fi
  '';
  endless = writeShellScript "endless" ''
    printf 'endless\n' >> "$CUT_TEST_LOG"
    touch "$NIXPKGS_KNIVES_CHANGED_FILE"
  '';
in
runCommand "test-cut-dispatcher" { nativeBuildInputs = [ diffutils ]; } ''
  run_cut() {
    ${bash}/bin/bash ${../cut} "$@"
  }

  mkdir basic
  ln -s ${zeta} basic/zeta
  ln -s ${alpha} basic/alpha
  export NIXPKGS_KNIVES_DIR="$PWD/basic"
  export CUT_TEST_LOG="$PWD/basic.log"

  run_cut > list.actual
  printf 'alpha\nzeta\n' > list.expected
  diff -u list.expected list.actual

  run_cut zeta
  printf 'zeta\n' > named.expected
  diff -u named.expected "$CUT_TEST_LOG"

  : > "$CUT_TEST_LOG"
  run_cut --all > all.output
  printf 'alpha\nzeta\n' > all.expected
  diff -u all.expected "$CUT_TEST_LOG"

  mkdir loop loop-state
  ln -s ${early} loop/early
  ln -s ${late} loop/late
  export NIXPKGS_KNIVES_DIR="$PWD/loop"
  export CUT_TEST_LOG="$PWD/loop.log"
  export CUT_TEST_STATE="$PWD/loop-state"

  run_cut --maniac > loop.output
  printf 'early\nlate\nearly\nlate\nearly\nlate\n' > loop.expected
  diff -u loop.expected "$CUT_TEST_LOG"
  grep -qx 'Converged after 3 iteration(s)' loop.output

  mkdir endless
  ln -s ${endless} endless/endless
  export NIXPKGS_KNIVES_DIR="$PWD/endless"
  export CUT_TEST_LOG="$PWD/endless.log"

  if run_cut --maniac > endless.output 2>&1; then
    echo '--maniac unexpectedly converged' >&2
    exit 1
  fi
  test "$(wc -l < "$CUT_TEST_LOG")" -eq 10
  grep -qx 'Still changing after 10 iterations' endless.output

  touch "$out"
''
