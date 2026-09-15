{ mode }:

assert builtins.elem mode [
  "driver"
  "test"
];

config: {
  # Preserve the test's attribute path while presenting a derivation leaf
  # to nix-eval-jobs. all-tests.nix handles legacy functions and nested sets.
  __job = if mode == "driver" then config.test.driver else config.test;
}
