{
  lib,
  runCommand,
  ast-grep,
  cut,
  diffutils,
}:

{
  name,
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

    ${cut}/bin/cut ${lib.escapeShellArg knife} > first-run.log
    test "$(head -n 1 first-run.log)" = ${lib.escapeShellArg "Found ${toString expectedCandidates} candidates"}

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

    ${cut}/bin/cut ${lib.escapeShellArg knife} > second-run.log
    test "$(head -n 1 second-run.log)" = "Found 0 candidates"

    mkdir "$out"
    cp actual.diff first-run.log second-run.log "$out/"
  ''
