{ pkgs }:
let
  libfprint-2-tod1-vfs0090-bingch = import ./libfprint-2-tod1-vfs0090-bingch.nix {
    pkgs = pkgs;
  };
in
{
  inherit (libfprint-2-tod1-vfs0090-bingch) libfprint-2-tod1-vfs0090-bingch;
}
