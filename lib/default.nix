{ pkgs, localPackages }:
let
  libfprint-2-tod1-vfs0090-bingch = import ./libfprint-2-tod1-vfs0090-bingch.nix {
    pkgs = pkgs;
    localPackages = localPackages;
  };
in
{
  inherit (libfprint-2-tod1-vfs0090-bingch) libfprint-2-tod1-vfs0090-bingch;
}
