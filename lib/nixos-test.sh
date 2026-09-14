#!/usr/bin/env bash

# Shared support for knives that rewrite runTest-style NixOS tests.

nixos_test_init() {
  nixos_tests_dir="${NIXOS_TESTS_DIR:-nixos/tests}"

  if [[ ! -d "$nixos_tests_dir" ]]; then
    echo "Test directory does not exist: $nixos_tests_dir" >&2
    exit 1
  fi

  ast_grep="${AST_GREP:-$(nix build --no-link --print-out-paths -f . ast-grep)/bin/ast-grep}"
}

# Match the pkgs formal belonging to the outer function.
nixos_test_root_pkgs_rule='
id: root-pkgs
language: nix
rule:
  all:
    - kind: identifier
    - regex: "^pkgs$"
    - inside:
        all:
          - kind: formal
          - inside:
              all:
                - kind: formals
                - inside:
                    all:
                      - kind: function_expression
                      - inside:
                          kind: source_code
                          stopBy: neighbor
                    stopBy: neighbor
              stopBy: neighbor
        stopBy: neighbor
'

# Match identifiers in the outer function argument set.
nixos_test_root_formal_rule='
id: root-formal
language: nix
rule:
  all:
    - kind: identifier
    - inside:
        all:
          - kind: formal
          - inside:
              all:
                - kind: formals
                - inside:
                    all:
                      - kind: function_expression
                      - inside:
                          kind: source_code
                          stopBy: neighbor
                    stopBy: neighbor
              stopBy: neighbor
        stopBy: neighbor
'

# Match actual uses of outer pkgs, excluding its formal, attribute names, and
# references below functions that bind their own pkgs.
nixos_test_root_pkgs_use_rule='
id: root-pkgs-use
language: nix
utils:
  pkgs-shadowing-function:
    all:
      - kind: function_expression
      - not:
          inside:
            kind: source_code
            stopBy: neighbor
      - has:
          all:
            - kind: formals
            - has:
                all:
                  - kind: formal
                  - has:
                      all:
                        - kind: identifier
                        - regex: "^pkgs$"
                      stopBy: neighbor
                stopBy: neighbor
          stopBy: neighbor
rule:
  all:
    - kind: identifier
    - regex: "^pkgs$"
    - inside:
        all:
          - kind: function_expression
          - inside:
              kind: source_code
              stopBy: neighbor
        stopBy: end
    - not:
        inside:
          kind: formals
          stopBy: end
    - not:
        inside:
          kind: attrpath
          stopBy: neighbor
    - not:
        inside:
          matches: pkgs-shadowing-function
          stopBy: end
'

nixos_test_root_pkgs_files() {
  "$ast_grep" scan \
    --inline-rules "$nixos_test_root_pkgs_rule" \
    --files-with-matches \
    --globs '!**/common/**' \
    "$nixos_tests_dir" |
    sort -u
}

nixos_test_root_args() {
  local file="$1"

  "$ast_grep" scan \
    --inline-rules "$nixos_test_root_formal_rule" \
    --json=stream \
    "$file" |
    jq -r '.text'
}

nixos_test_has_root_arg() {
  local file="$1"
  local argument="$2"

  nixos_test_root_args "$file" | grep -qx "$argument"
}

nixos_test_has_expected_root_args() {
  local file="$1"
  local unexpected_args

  unexpected_args=$(
    nixos_test_root_args "$file" |
      grep -Ev '^(config|hostPkgs|lib|nodes|options|pkgs)$' ||
      true
  )
  [[ -z "$unexpected_args" ]]
}

nixos_test_is_named() {
  local file="$1"

  grep -q '^  name = ' "$file"
}

nixos_test_apply_rule() {
  local rule="$1"
  local file="$2"
  local output

  if ! output=$(
    "$ast_grep" scan \
      --inline-rules "$rule" \
      --update-all \
      "$file" 2>&1
  ); then
    printf '%s\n' "$output" >&2
    exit 1
  fi
}

nixos_test_root_arg_location() {
  local file="$1"
  local argument="$2"

  "$ast_grep" scan \
    --inline-rules "$nixos_test_root_formal_rule" \
    --json=stream \
    "$file" |
    jq -r --arg argument "$argument" \
      'select(.text == $argument) | "\(.range.start.line + 1) \(.range.start.column)"'
}

nixos_test_add_root_arg() {
  local file="$1"
  local argument="$2"
  local location line column

  nixos_test_has_root_arg "$file" "$argument" && return

  location=$(nixos_test_root_arg_location "$file" pkgs)
  read -r line column <<< "$location"

  # Insert before pkgs. Preserve single-line and multiline argument layouts.
  TARGET_LINE="$line" TARGET_COLUMN="$column" ARGUMENT="$argument" perl -i -pe '
    next unless $. == $ENV{TARGET_LINE};

    my $column = $ENV{TARGET_COLUMN};
    my $before = substr($_, 0, $column);
    my $formal = substr($_, $column, 4);
    my $after = substr($_, $column + 4);

    die "expected pkgs at line $ENV{TARGET_LINE}, column $column\n"
      unless $formal eq "pkgs";

    if ($before =~ /^(\s*)$/) {
      $_ = $before . $ENV{ARGUMENT} . ",\n" . $before . $formal . $after;
    } else {
      $_ = $before . $ENV{ARGUMENT} . ", " . $formal . $after;
    }
  ' "$file"
}

nixos_test_remove_root_pkgs() {
  local file="$1"
  local location line column

  location=$(nixos_test_root_arg_location "$file" pkgs)
  read -r line column <<< "$location"

  # Remove a standalone formal line, or its adjacent comma on a single line.
  TARGET_LINE="$line" TARGET_COLUMN="$column" perl -i -pe '
    next unless $. == $ENV{TARGET_LINE};

    my $column = $ENV{TARGET_COLUMN};
    my $before = substr($_, 0, $column);
    my $formal = substr($_, $column, 4);
    my $after = substr($_, $column + 4);

    die "expected pkgs at line $ENV{TARGET_LINE}, column $column\n"
      unless $formal eq "pkgs";

    if ($before =~ /^\s*$/ && $after =~ /^[ \t]*,?[ \t]*(?:\r?\n)?$/) {
      $_ = "";
    } elsif ($after =~ s/^[ \t]*,[ \t]*//) {
      $_ = $before . $after;
    } elsif ($before =~ s/,[ \t]*$//) {
      $_ = $before . $after;
    } else {
      $_ = $before . $after;
    }
  ' "$file"
}

nixos_test_remove_unused_root_pkgs() {
  local file="$1"
  local remaining_pkgs_uses

  remaining_pkgs_uses=$(
    "$ast_grep" scan \
      --inline-rules "$nixos_test_root_pkgs_use_rule" \
      --json=stream \
      "$file"
  )

  if [[ -z "$remaining_pkgs_uses" ]]; then
    nixos_test_remove_root_pkgs "$file"
  fi
}

nixos_test_parse() {
  local file="$1"

  # Parsing needs no store; dummy avoids contacting the Nix daemon in sandboxes.
  nix-instantiate --store dummy:// --parse "$file" >/dev/null
}

nixos_test_finish() {
  if [[ "$nixos_tests_dir" == nixos/tests ]]; then
    git diff --check
    git diff --stat
  fi
}
