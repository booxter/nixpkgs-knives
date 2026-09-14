{ pkgs, ... }:
{
  name = "test-script-packages-mixed";

  testScript = ''
    machine.succeed("${pkgs.hello}/bin/hello")
    subprocess.run("${pkgs.hello}/bin/hello")
  '';
}
