# This package builds an updated version of https://gitlab.freedesktop.org/uunicorn/fprintd/-/tree/debian/clients-only
# It provides the fprintd-enroll, fprintd-list, etc. user utilties when using open-fprintd.
#
# Beyond installing only a subset of its files, there are no actual differences from the fprintd package in Nixpkgs.
{
  lib,
  fprintd,
}:
fprintd.overrideAttrs ({
  patches ? [],
  mesonFlags ? [],
  ...
}: {
  pname = "fprintd-clients";

  patches = patches ++ [./Make-building-the-daemon-optional.patch];
  mesonFlags =
    mesonFlags
    ++ [
      (lib.mesonBool "daemon" false)
      (lib.mesonBool "pam" true)
      (lib.mesonBool "systemd" false)
    ];

  meta.homepage = "https://gitlab.freedesktop.org/uunicorn/fprintd/-/tree/debian/clients-only";
  meta.description = "fprintd without the daemon";
})
