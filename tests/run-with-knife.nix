{
  lib,
  runCommand,
  ast-grep,
  cut,
  diffutils,
}:

{
  name,
  group,
  knife,
  fixture,
  files,
  expectedCandidates,
  expectedDiff ? null,
}:

runCommand "test-${name}"
  {
    nativeBuildInputs = [ diffutils ];
  }
  ''
    set -euo pipefail

    mkdir -p original work
    ${lib.concatMapStringsSep "\n" (file: ''
      mkdir -p "original/$(dirname ${lib.escapeShellArg file})"
      mkdir -p "work/$(dirname ${lib.escapeShellArg file})"
      cp ${fixture}/${file} "original/${file}"
      cp ${fixture}/${file} "work/${file}"
      chmod u+w "work/${file}"
    '') files}

    export AST_GREP=${lib.getExe ast-grep}
    export NIXOS_TESTS_DIR="$PWD/work/nixos/tests"
    export NIXPKGS_KNIVES_CHANGED_FILE="$PWD/changed"

    ${cut}/bin/cut --group ${lib.escapeShellArg group} ${lib.escapeShellArg knife} > first-run.log
    test "$(head -n 1 first-run.log)" = ${lib.escapeShellArg "Found ${toString expectedCandidates} candidates"}
    ${
      if expectedCandidates == 0 then
        "test ! -e \"$NIXPKGS_KNIVES_CHANGED_FILE\""
      else
        "test -e \"$NIXPKGS_KNIVES_CHANGED_FILE\""
    }

    touch actual.diff
    ${lib.concatMapStringsSep "\n" (file: ''
      status=0
      diff -u \
        --label ${lib.escapeShellArg "a/${file}"} \
        --label ${lib.escapeShellArg "b/${file}"} \
        "original/${file}" \
        "work/${file}" >> actual.diff || status=$?
      test "$status" -le 1
    '') files}

    ${
      if expectedDiff == null then
        ''
          test ! -s actual.diff
        ''
      else
        ''
          diff -u ${expectedDiff} actual.diff
        ''
    }

    rm -f "$NIXPKGS_KNIVES_CHANGED_FILE"
    ${cut}/bin/cut --group ${lib.escapeShellArg group} ${lib.escapeShellArg knife} > second-run.log
    test "$(head -n 1 second-run.log)" = "Found 0 candidates"
    test ! -e "$NIXPKGS_KNIVES_CHANGED_FILE"

    mkdir "$out"
    cp actual.diff first-run.log second-run.log "$out/"
  ''
