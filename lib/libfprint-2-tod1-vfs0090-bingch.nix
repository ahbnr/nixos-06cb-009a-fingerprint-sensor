{ pkgs, localPackages }:
{
  libfprint-2-tod1-vfs0090-bingch = { calib-data-file }:
    pkgs.callPackage ../pkgs/libfprint-2-tod1-vfs0090-bingch {
      calib-data = pkgs.callPackage ../pkgs/calib-data { calib-data-file = calib-data-file; };
      python-validity = localPackages.python-validity;
    };
}
