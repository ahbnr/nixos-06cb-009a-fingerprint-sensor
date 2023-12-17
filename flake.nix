{
  description = "Provides packages, modules and functions for the 06cb:009a fingerprint sensor.";

  inputs = {
    nixpkgs.url = "nixpkgs/nixos-23.11";
  };

  outputs = {
    self,
    nixpkgs
  }: let
    pkgs = import nixpkgs { system = "x86_64-linux"; };
    localPackages = import ./pkgs/default.nix { pkgs = pkgs; };
  in {
    nixosModules.python-validity = { config, lib, ... }: import ./modules/python-validity { config = config; lib = lib; localPackages = localPackages; };
    nixosModules.open-fprintd = { config, lib, ... }: import ./modules/open-fprintd { config = config; lib = lib; localPackages = localPackages; };

    localPackages = localPackages;

    lib = import ./lib {
      pkgs = pkgs;
      localPackages = localPackages;
    };
  };
}
