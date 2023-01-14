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

    packages = forAllSystems (system:
      import ./default.nix {
        pkgs = import nixpkgs {inherit system;};
      }
    );
  };
}
