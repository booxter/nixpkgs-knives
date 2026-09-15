{
  lib,
  stdenvNoCC,
  makeWrapper,
  coreutils,
  gitMinimal,
  gnugrep,
  gnutar,
  jq,
  nix,
  nix-eval-jobs,
  perl,
}:

stdenvNoCC.mkDerivation {
  pname = "nixpkgs-knives";
  version = "0.1.0";
  src = ./.;

  nativeBuildInputs = [ makeWrapper ];

  installPhase = ''
    runHook preInstall

    mkdir -p "$out/bin" "$out/share/nixpkgs-knives/lib"
    cp cut verify "$out/bin/"
    cp -R groups "$out/share/nixpkgs-knives/"
    cp lib/* "$out/share/nixpkgs-knives/lib/"
    cp -R ast-grep "$out/share/nixpkgs-knives/"
    patchShebangs "$out/bin" "$out/share/nixpkgs-knives/groups"

    for dispatcher in "$out/bin/cut" "$out/bin/verify"; do
      wrapProgram "$dispatcher" \
        --set NIXPKGS_KNIVES_GROUPS_DIR "$out/share/nixpkgs-knives/groups" \
        --prefix PATH : ${lib.makeBinPath [ coreutils ]}
    done

    for group in "$out/share/nixpkgs-knives/groups"/*; do
      for knife in "$group/bin"/*; do
        [[ -f "$knife" ]] || continue
        wrapProgram "$knife" \
          --prefix PATH : ${
            lib.makeBinPath [
              coreutils
              gnugrep
              jq
              nix
              perl
            ]
          }
      done

      if [[ -x "$group/verify" ]]; then
        wrapProgram "$group/verify" \
          --prefix PATH : ${
            lib.makeBinPath [
              coreutils
              gitMinimal
              gnutar
              jq
              nix
              nix-eval-jobs
            ]
          }
      fi
    done

    runHook postInstall
  '';
}
