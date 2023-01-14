
{ pkgs ? import <nixpkgs> {} }: rec {
  open-fprintd = (pkgs.callPackage ./pkgs/open-fprintd {});
  fprintd-clients = (pkgs.callPackage ./pkgs/fprintd-clients {});
  python-validity = (pkgs.callPackage ./pkgs/python-validity {});
}
