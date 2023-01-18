
{ pkgs }: rec {
  open-fprintd = (pkgs.callPackage ./open-fprintd {});
  fprintd-clients = (pkgs.callPackage ./fprintd-clients {});
  python-validity = (pkgs.callPackage ./python-validity {});
}
