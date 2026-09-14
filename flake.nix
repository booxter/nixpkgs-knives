{
  description = "Mechanical migrations for Nixpkgs";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  inputs.treefmt-nix = {
    url = "github:numtide/treefmt-nix";
    inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs =
    {
      self,
      nixpkgs,
      treefmt-nix,
      ...
    }:
    let
      systems = [
        "aarch64-darwin"
        "aarch64-linux"
        "x86_64-linux"
      ];
      forAllSystems = nixpkgs.lib.genAttrs systems;
      treefmt = forAllSystems (
        system: treefmt-nix.lib.evalModule nixpkgs.legacyPackages.${system} ./treefmt.nix
      );
    in
    {
      packages = forAllSystems (
        system:
        let
          cut = nixpkgs.legacyPackages.${system}.callPackage ./package.nix { };
        in
        {
          inherit cut;
          default = cut;
        }
      );

      apps = forAllSystems (system: {
        cut = {
          type = "app";
          program = "${self.packages.${system}.cut}/bin/cut";
        };
      });

      formatter = forAllSystems (system: treefmt.${system}.config.build.wrapper);

      checks = forAllSystems (system: {
        formatting = treefmt.${system}.config.build.check self;
      });
    };
}
