#!/usr/bin/env bash

# Shared support for knives that rewrite runTest-style NixOS tests.

nixos_test_lib_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

nixos_test_init() {
  nixos_tests_dir="${NIXOS_TESTS_DIR:-nixos/tests}"

  if [[ ! -d "$nixos_tests_dir" ]]; then
    echo "Test directory does not exist: $nixos_tests_dir" >&2
    exit 1
  fi

  ast_grep="${AST_GREP:-$(nix build --no-link --print-out-paths -f . ast-grep)/bin/ast-grep}"
  ast_grep_config="${AST_GREP_CONFIG:-$nixos_test_lib_dir/../ast-grep/sgconfig.yml}"
}

nixos_test_scan_rule() {
  local rule_id="$1"
  shift

  "$ast_grep" scan \
    --config "$ast_grep_config" \
    --filter "^${rule_id}$" \
    "$@"
}

nixos_test_root_pkgs_files() {
  nixos_test_scan_rule nixos-test-root-formal \
    --json=stream \
    --globs '!**/common/**' \
    "$nixos_tests_dir" |
    jq -r 'select(.text == "pkgs") | .file' |
    sort -u
}

nixos_test_matches_rule() {
  local rule_id="$1"
  local file="$2"
  local matches

  matches=$(
    nixos_test_scan_rule "$rule_id" \
      --json=stream \
      "$file"
  )
  [[ -n "$matches" ]]
}

nixos_test_rule_match_count() {
  local rule_id="$1"
  local file="$2"

  nixos_test_scan_rule "$rule_id" \
    --json=stream \
    "$file" |
    jq -s length
}

nixos_test_root_args() {
  local file="$1"

  nixos_test_scan_rule nixos-test-root-formal \
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

nixos_test_is_simple_test() {
  local file="$1"

  nixos_test_is_named "$file" && nixos_test_has_expected_root_args "$file"
}

nixos_test_apply_rule() {
  local rule_id="$1"
  local file="$2"
  local output

  if ! output=$(
    nixos_test_scan_rule "$rule_id" \
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

  nixos_test_scan_rule nixos-test-root-formal \
    --json=stream \
    "$file" |
    jq -r --arg argument "$argument" \
      'select(.text == $argument) | "\(.range.start.line + 1) \(.range.start.column)"'
}

nixos_test_add_root_arg() {
  local file="$1"
  local argument="$2"
  local declaration="${3:-$argument}"
  local location line column

  nixos_test_has_root_arg "$file" "$argument" && return

  location=$(nixos_test_root_arg_location "$file" pkgs)
  read -r line column <<< "$location"

  # Insert before pkgs. Preserve single-line and multiline argument layouts.
  TARGET_LINE="$line" TARGET_COLUMN="$column" DECLARATION="$declaration" perl -i -pe '
    next unless $. == $ENV{TARGET_LINE};

    my $column = $ENV{TARGET_COLUMN};
    my $before = substr($_, 0, $column);
    my $formal = substr($_, $column, 4);
    my $after = substr($_, $column + 4);

    die "expected pkgs at line $ENV{TARGET_LINE}, column $column\n"
      unless $formal eq "pkgs";

    if ($before =~ /^(\s*)$/) {
      $_ = $before . $ENV{DECLARATION} . ",\n" . $before . $formal . $after;
    } else {
      $_ = $before . $ENV{DECLARATION} . ", " . $formal . $after;
    }
  ' "$file"
}

nixos_test_rename_root_arg() {
  local file="$1"
  local from="$2"
  local to="$3"
  local location line column

  location=$(nixos_test_root_arg_location "$file" "$from")
  read -r line column <<< "$location"

  # Replace only the formal name, preserving defaults and surrounding layout.
  TARGET_LINE="$line" TARGET_COLUMN="$column" FROM="$from" TO="$to" perl -i -pe '
    next unless $. == $ENV{TARGET_LINE};

    my $column = $ENV{TARGET_COLUMN};
    my $before = substr($_, 0, $column);
    my $formal = substr($_, $column, length($ENV{FROM}));
    my $after = substr($_, $column + length($ENV{FROM}));

    die "expected $ENV{FROM} at line $ENV{TARGET_LINE}, column $column\n"
      unless $formal eq $ENV{FROM};

    $_ = $before . $ENV{TO} . $after;
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
    nixos_test_scan_rule nixos-test-root-pkgs-use \
      --json=stream \
      "$file"
  )

  if [[ -z "$remaining_pkgs_uses" ]]; then
    nixos_test_remove_root_pkgs "$file"
  fi
}

nixos_test_reconcile_root_pkgs() {
  local file="$1"
  local replacement="$2"

  if nixos_test_matches_rule nixos-test-root-pkgs-use "$file"; then
    nixos_test_add_root_arg "$file" "$replacement"
  elif nixos_test_has_root_arg "$file" "$replacement"; then
    nixos_test_remove_root_pkgs "$file"
  else
    nixos_test_rename_root_arg "$file" pkgs "$replacement"
  fi
}

nixos_test_parse() {
  local file="$1"

  # Parsing needs no store; dummy avoids contacting the Nix daemon in sandboxes.
  nix-instantiate --store dummy:// --parse "$file" >/dev/null
}

nixos_test_run() {
  local candidate_function="$1"
  local migrate_function="$2"
  local file
  local -a files=()

  while IFS= read -r file; do
    "$candidate_function" "$file" || continue
    files+=("$file")
  done < <(nixos_test_root_pkgs_files)

  printf 'Found %d candidates\n' "${#files[@]}"
  printf '%s\n' "${files[@]}"

  if [[ "${#files[@]}" -eq 0 ]]; then
    return
  fi

  for file in "${files[@]}"; do
    "$migrate_function" "$file"
    nixos_test_parse "$file"
  done

  # Let repeated dispatcher passes know that this knife applied changes.
  if [[ -n "${NIXPKGS_KNIVES_CHANGED_FILE:-}" ]]; then
    touch "$NIXPKGS_KNIVES_CHANGED_FILE"
  fi
}
