{
  description = "Provides packages, modules and functions for the 06cb:009a fingerprint sensor.";

  inputs = {
    nixpkgs.url = "nixpkgs/nixos-24.11";
  };

  outputs = {
    self,
    nixpkgs
  }: let
    pkgs = import nixpkgs { system = "x86_64-linux"; };
    localPackages = import ./pkgs/default.nix { pkgs = pkgs; };
    localLib = import ./lib {
      pkgs = pkgs;
      localPackages = localPackages;
    };
  in {
    nixosModules.python-validity = args: import ./modules/python-validity (
      args // {
        localPackages = localPackages;
      }
    );

    nixosModules.open-fprintd = ./modules/open-fprintd;

    nixosModules."06cb-009a-fingerprint-sensor" = args: import ./modules/06cb-009a-fingerprint-sensor (
      args // {
        localPackages = localPackages;
        libfprint-2-tod1-vfs0090-bingch = localLib.libfprint-2-tod1-vfs0090-bingch;
      }
    );
  };
}
