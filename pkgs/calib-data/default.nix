{
  stdenv,
  pkgs ? import <nixpkgs> { system = builtins.currentSystem; },
  calib-data-file
}:

stdenv.mkDerivation rec {
  pname = "calib-data";
  version = "0.0.1";

  src = calib-data-file;

  unpackPhase = "true";

  installPhase = ''
    mkdir -p $out/share

    install -D -m 644 $src \
      $out/share/calib-data.bin
  '';
}
