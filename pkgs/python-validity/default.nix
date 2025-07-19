{
  pkgs,
  lib,
  fetchFromGitHub,
  python3Packages,
}: let
  inherit (python3Packages) python buildPythonPackage;
in
  buildPythonPackage rec {
    pname = "python-validity";
    version = "0.15";
    pyproject = true;

    src = fetchFromGitHub {
      owner = "uunicorn";
      repo = pname;
      rev = "${version}";
      sha256 = "sha256-RflX7e6nd11pSg8mh3mjZiVGNUSdox/SKXHR4W+PhMs="; # set to lib.fakeSha256 first to get the hash
    };

    build-system = with python3Packages; [
      setuptools
    ];

    patches = [
      # rename dbus service executable
      ./python-validity-dbus-service.patch

      # in the original setup.py, the dbus-service executable is not installed in /bin, but as a data file to a non-standard location.
      # Hence, we remove its declaration as a data file and declare it as a script instead, so that it is installed to /bin.
      # This is because the buildPythonPackage wrapper will only wrap the executable correctly if it is in the /bin directory
      ./setup.py.patch
   ];

    postPatch = ''
      # the firmware download script depends on innoextract
      substituteInPlace bin/validity-sensors-firmware \
            --replace "'innoextract'" \
                      "'${pkgs.innoextract}/bin/innoextract'"

      # change service file to use the new executable path
      substituteInPlace debian/python3-validity.service \
            --replace "ExecStart=/usr/lib/python-validity/dbus-service" \
                      "ExecStart=$out/bin/python-validity-dbus-service" \
            --replace " --debug" ""
    '';

    nativeBuildInputs = with pkgs; [
      wrapGAppsNoGuiHook
    ];

    propagatedBuildInputs = with python3Packages; [
      cryptography
      pyusb
      pyyaml
      dbus-python
      pygobject3
    ];

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
