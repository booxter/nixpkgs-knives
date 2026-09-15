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

  mkdir -p basic/nixos/bin
  ln -s ${zeta} basic/nixos/bin/zeta
  ln -s ${alpha} basic/nixos/bin/alpha
  export NIXPKGS_KNIVES_GROUPS_DIR="$PWD/basic"
  export CUT_TEST_LOG="$PWD/basic.log"

  if run_cut > missing-group.actual 2>&1; then
    echo 'cut unexpectedly accepted a missing group' >&2
    exit 1
  fi
  printf 'Usage: cut --group GROUP [KNIFE | --all | --maniac]\nAvailable groups:\n  nixos\n' > missing-group.expected
  diff -u missing-group.expected missing-group.actual

  run_cut --group nixos > list.actual
  printf 'alpha\nzeta\n' > list.expected
  diff -u list.expected list.actual

  run_cut --group nixos zeta
  printf 'zeta\n' > named.expected
  diff -u named.expected "$CUT_TEST_LOG"

  : > "$CUT_TEST_LOG"
  run_cut --group nixos --all > all.output
  printf 'alpha\nzeta\n' > all.expected
  diff -u all.expected "$CUT_TEST_LOG"

  mkdir -p loop/nixos/bin loop-state
  ln -s ${early} loop/nixos/bin/early
  ln -s ${late} loop/nixos/bin/late
  export NIXPKGS_KNIVES_GROUPS_DIR="$PWD/loop"
  export CUT_TEST_LOG="$PWD/loop.log"
  export CUT_TEST_STATE="$PWD/loop-state"

  run_cut --group nixos --maniac > loop.output
  printf 'early\nlate\nearly\nlate\nearly\nlate\n' > loop.expected
  diff -u loop.expected "$CUT_TEST_LOG"
  printf '%s\n' \
    'Iteration 1' '==> early' '==> late' \
    'Iteration 2' '==> early' '==> late' \
    'Iteration 3' '==> early' '==> late' \
    'Converged after 3 iteration(s)' > loop-output.expected
  diff -u loop-output.expected loop.output

  mkdir -p endless/nixos/bin
  ln -s ${endless} endless/nixos/bin/endless
  export NIXPKGS_KNIVES_GROUPS_DIR="$PWD/endless"
  export CUT_TEST_LOG="$PWD/endless.log"

  if run_cut --group nixos --maniac > endless.output 2>&1; then
    echo '--maniac unexpectedly converged' >&2
    exit 1
  fi
  test "$(wc -l < "$CUT_TEST_LOG")" -eq 10
  : > endless.expected
  for iteration in {1..10}; do
    printf 'Iteration %d\n==> endless\n' "$iteration" >> endless.expected
  done
  printf 'Still changing after 10 iterations\n' >> endless.expected
  diff -u endless.expected endless.output

  touch "$out"
''
