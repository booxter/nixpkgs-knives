{ runCommand }:

let
  selectTest = import ../nix/select-nixos-test-job.nix { mode = "test"; };
  selectDriver = import ../nix/select-nixos-test-job.nix { mode = "driver"; };

  driver = runCommand "test-driver" { } "touch $out";
  testBase = runCommand "nixos-test" { } "touch $out";
  test = testBase // {
    inherit driver;
    nodes = { };
    test = testBase;
  };

  config = { inherit test; };
in
assert (selectTest config).__job.drvPath == test.drvPath;
assert (selectDriver config).__job.drvPath == driver.drvPath;
runCommand "test-nixos-test-job-selection" { } "touch $out"
