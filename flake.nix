{
  description = "Provides packages, modules and functions for the 06cb:009a fingerprint sensor.";

  inputs = {
    nixpkgs.url = "nixpkgs/nixos-22.11";
  };

  outputs = {
    self,
    nixpkgs
  }: let
    supportedSystems = [ "x86_64-linux" ];
    forAllSystems = f: nixpkgs.lib.genAttrs supportedSystems (system: f system);
    pkgs = import nixpkgs {};
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
