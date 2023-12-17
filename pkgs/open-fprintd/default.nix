{
  pkgs,
  lib,
  stdenv,
  fetchFromGitHub,
  python3Packages,
  substituteAll
}:

let
  inherit (python3Packages) python buildPythonPackage;
in buildPythonPackage rec {
  pname = "open-fprintd";
  version = "0.6";

  src = fetchFromGitHub {
    owner = "uunicorn";
    repo = pname;
    rev = "${version}";
    sha256 = "sha256-uVFuwtsmR/9epoqot3lJ/5v5OuJjuRjL7FJF7oXNDzU="; # set to lib.fakeSha256 first to get the hash
  };

  patches = [
    ./setup.py.patch
    ./scripts.patch
  ];

  postPatch = ''
    # We now edit in nix store paths where necessary

    substituteInPlace debian/open-fprintd.service \
      --replace "ExecStart=/usr/lib/open-fprintd/open-fprintd" \
                "ExecStart=$out/bin/open-fprintd"

    substituteInPlace debian/open-fprintd-suspend.service \
      --replace "ExecStart=/usr/lib/open-fprintd/suspend.py" \
                "ExecStart=$out/bin/open-fprintd-suspend.py"

    substituteInPlace debian/open-fprintd-resume.service \
      --replace "ExecStart=/usr/lib/open-fprintd/resume.py" \
                "ExecStart=$out/bin/open-fprintd-resume.py"
  '';

  propagatedBuildInputs = with python3Packages; [
    dbus-python
    pygobject3
  ];

  postInstall = ''
    # this section has been adapted from this AUR package: https://aur.archlinux.org/cgit/aur.git/tree/PKGBUILD?h=open-fprintd

    install -D -m 644 debian/open-fprintd.service \
      $out/lib/systemd/system/open-fprintd.service

    install -D -m 644 debian/open-fprintd-resume.service \
      $out/lib/systemd/system/open-fprintd-resume.service

    install -D -m 644 debian/open-fprintd-suspend.service \
      $out/lib/systemd/system/open-fprintd-suspend.service
  '';

  meta = with lib; {
    description = "Fprintd replacement which allows you to have your own backend as a standalone service";
    homepage = "https://github.com/uunicorn/open-fprintd";
    license = licenses.gpl2;
  };
}
