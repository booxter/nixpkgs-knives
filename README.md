# nixpkgs-knives

Mechanical, idempotent migrations for Nixpkgs. Knives modify files in place and
parse-check every changed Nix file.

Run from the root of a Nixpkgs checkout:

```console
nix run /path/to/nixpkgs-knives#cut
nix run /path/to/nixpkgs-knives#cut -- nixos-test-system-packages
```

With no knife name, cut lists the available knives. Use `--all` to run each
knife once, or `--maniac` to repeat all knives until they stop making changes
(at most ten passes). Review the resulting `git diff` before committing.

Run the checks with:

```console
nix flake check
```
