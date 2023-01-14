{
  description = "Provides python-validity and its dependencies open-fprintd and fprintd-clients.";

  inputs = {
    nixpkgs.url = "nixpkgs/nixos-22.11";
  };

  outputs = {
    self,
    nixpkgs
  }: let
    supportedSystems = [ "x86_64-linux" ];
    forAllSystems = f: nixpkgs.lib.genAttrs supportedSystems (system: f system);
  in {
    nixosModules.python-validity = import ./modules/python-validity;
    nixosModules.open-fprintd = import ./modules/open-fprintd;

    overlay = final: prev: let
      localPkgs = import ./default.nix { pkgs = final; };
    in {
      inherit (localPkgs) fprintd-clients open-fprintd python-validity;
    };

    packages = forAllSystems (system:
      import ./default.nix {
        pkgs = import nixpkgs {inherit system;};
      }
    );
  };
}
