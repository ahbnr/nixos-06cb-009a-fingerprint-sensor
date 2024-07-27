{
  pkgs,
  lib,
  stdenv,
  fetchFromGitHub,
  python3Packages,
}: let
  inherit (python3Packages) python buildPythonPackage;
in
  buildPythonPackage rec {
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
      ./dbus-service.patch

      # similarly, state data needs to go to /var/lib
      ./sensor.py.patch

      # rename dbus service executable
      ./python-validity-dbus-service.patch

      # in the original setup.py, the dbus-service executable is not installed in /bin, but as a data file to a non-standard location.
      # Hence, we remove its declaration as a data file and declare it as a script instead, so that it is installed to /bin.
      # This is because the buildPythonPackage wrapper will only wrap the executable correctly if it is in the /bin directory
      ./setup.py.patch

      # The firmware download script is run as part of the installation process on other distributions.
      # However, it tries to identify the system hardware and download different firmware packages depending on the results.
      #
      # This sort of side-effect related behaviour is probably not ideal to have in the build process of a Nix package.
      # Instead, the user shall call `validity-sensors-firmware` themselves when using python validity for the first time.
      # TODO: We should make it so, that the python-validity service downloads the firmware automatically when not present.
      #
      # Hence, we patch the firmware download script so that it downloads the firmware to a temporary directory, instead of trying
      # to write to /usr/share or the Nix store
      ./validity-sensors-firmware.patch

      # Because of the above firmware downloading patch, we also have patch the firmware search location in the script which
      # performs the firmware installation
      ./upload_fwext.py.patch
    ];

    postPatch = ''
      # add support for using a temporary directory, which is needed for multiple of the above patches
      cp ${./tmpdir.py} validitysensor/tmpdir.py

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
