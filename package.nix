{
  lib,
  stdenvNoCC,
  makeWrapper,
  coreutils,
  git,
  gnugrep,
  jq,
  nix,
  perl,
}:

stdenvNoCC.mkDerivation {
  pname = "nixpkgs-knives";
  version = "0.1.0";
  src = ./.;

  nativeBuildInputs = [ makeWrapper ];

  installPhase = ''
    runHook preInstall

    mkdir -p "$out/bin" "$out/share/nixpkgs-knives/bin" "$out/share/nixpkgs-knives/lib"
    cp cut "$out/bin/cut"
    cp bin/* "$out/share/nixpkgs-knives/bin/"
    cp lib/* "$out/share/nixpkgs-knives/lib/"
    cp -R ast-grep "$out/share/nixpkgs-knives/"
    patchShebangs "$out/bin" "$out/share/nixpkgs-knives/bin"

    wrapProgram "$out/bin/cut" \
      --set NIXPKGS_KNIVES_DIR "$out/share/nixpkgs-knives/bin"

    for knife in "$out/share/nixpkgs-knives/bin"/*; do
      wrapProgram "$knife" \
        --prefix PATH : ${
          lib.makeBinPath [
            coreutils
            git
            gnugrep
            jq
            nix
            perl
          ]
        }
    done

    runHook postInstall
  '';
}
