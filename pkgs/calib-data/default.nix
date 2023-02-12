# The libfprint-tod-vfs0090 fork by bingch requires calibration data for the 06cb:009a sensor.
# See also https://gitlab.com/bingch/libfprint-tod-vfs0090/-/blob/master/README.md#device-initialization-and-pairing-and-enroll-finger-on-chip
#
# This derivation stores the calibration data file in the nix store, so that it can be accessed by the builder of
# ../pkgs/libfprint-2-tod1-vfs0090-bingch
{
  stdenv,
  pkgs,
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
