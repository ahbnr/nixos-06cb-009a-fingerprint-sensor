{
  pkgs,
  lib,
  stdenv,
  fetchFromGitHub,
  python3Packages
}:

let
  inherit (python3Packages) python buildPythonPackage;
in buildPythonPackage rec {
  pname = "python-validity";
  version = "0.14";

  src = fetchFromGitHub {
    owner = "uunicorn";
    repo = pname;
    rev = "${version}";
    sha256 = "sha256-6NbxeokbGW5yP3g9Q/W3k0JiU6g+qyeZfKfw0nBJ37o="; # set to lib.fakeSha256 first to get the hash
  };

  patches = [
    # the service writes to a temporary file in usr/share, which is write-protected in Nix.
    # Instead, we let it write to the appropriate location for temporary files
    # TODO: Let the service evaluate $TMPDIR instead of hardcoding /tmp
    ./dbus-service.patch

    # similarly, state data needs to go to /var/lib
    ./sensor.py.patch

    # rename dbus service executable
    ./python-validity-dbus-service.patch

    # in the original setup.py, the dbus-service executable is not installed in /bin, but as a data file to a non-standard location.
    # Hence, we remove its declaration as a data file and declare it as a script instead, so that it is installed to /bin.
    # This is because the buildPythonPackage wrapper will only wrap the executable correctly if it is in the /bin directory
    ./setup.py.patch
  ];

  postPatch = ''
    # we need to adjust some data paths to use different locations, compatible with Nix
    substituteInPlace bin/validity-sensors-firmware \
          --replace "python_validity_data = '/usr/share/python-validity/'" \
                    "python_validity_data = '$out/share/python-validity/'"

    substituteInPlace validitysensor/upload_fwext.py \
          --replace "firmware_home = '/usr/share/python-validity'" \
                    "firmware_home = '$out/share/python-validity'"

    # change service file to use the new executable path
    substituteInPlace debian/python3-validity.service \
          --replace "ExecStart=/usr/lib/python-validity/dbus-service" \
                    "ExecStart=$out/bin/python-validity-dbus-service"
  '';

  propagatedBuildInputs = with python3Packages; [
    cryptography
    pyusb
    pyyaml
    dbus-python
    pygobject3
  ];

  # circumvent known bug in setuptools regarding data file installation: https://github.com/NixOS/nixpkgs/blob/master/doc/languages-frameworks/python.section.md#install_data--data_files-problems-install_data-data_files-problems
  preInstall = ''
    ${python.interpreter} setup.py install_data --install-dir=$out --root=$out
  '';

  postInstall = ''
    # this section has been adapted from this AUR package https://aur.archlinux.org/cgit/aur.git/tree/PKGBUILD?h=python-validity

    install -D -m 644 debian/python3-validity.service \
      $out/lib/systemd/system/python3-validity.service

    install -D -m 644 debian/python3-validity.udev \
      $out/lib/udev/rules.d/60-python-validity.rules

    install -Dm644 LICENSE \
      $out/share/licenses/${pname}/LICENSE
  '';

  meta = with lib; {
    description = "Validity fingerprint sensor driver";
    homepage = "https://github.com/uunicorn/python-validity";
    license = licenses.mit;
  };
}
