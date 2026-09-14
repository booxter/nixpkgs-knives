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

    mkdir -p "$out/bin" "$out/share/nixpkgs-knives/bin" "$out/share/nixpkgs-knives/lib"
    cp cut verify "$out/bin/"
    cp bin/* "$out/share/nixpkgs-knives/bin/"
    cp lib/* "$out/share/nixpkgs-knives/lib/"
    cp -R ast-grep "$out/share/nixpkgs-knives/"
    cp -R nix "$out/share/nixpkgs-knives/"
    patchShebangs "$out/bin" "$out/share/nixpkgs-knives/bin"

    wrapProgram "$out/bin/cut" \
      --set NIXPKGS_KNIVES_DIR "$out/share/nixpkgs-knives/bin" \
      --prefix PATH : ${lib.makeBinPath [ coreutils ]}

    wrapProgram "$out/bin/verify" \
      --set NIXPKGS_KNIVES_NIX_DIR "$out/share/nixpkgs-knives/nix" \
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

    for knife in "$out/share/nixpkgs-knives/bin"/*; do
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

    runHook postInstall
  '';
}
