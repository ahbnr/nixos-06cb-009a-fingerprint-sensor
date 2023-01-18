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

    lib = import ./lib {
      pkgs = import <nixpkgs> {};
    };

    overlay = final: prev: let
      localPkgs = import ./default.nix { pkgs = final; };
    in {
      inherit (localPkgs) fprintd-clients open-fprintd python-validity;
    };

    # overlays.libfprint-2-tod1-vfs0090-bingch = { calibDataPath }: final: prev: let
    #   localPkgs = import ./default.nix { pkgs = final; };
    # in {
    #   libfprint-2-tod1-vfs0090 = prev.libfprint-2-tod1-vfs0090.overrideAttrs (old: {
    #     src = prev.fetchFromGitLab {
    #       domain = "gitlab.com";
    #       owner = "bingch";
    #       repo = "libfprint-tod-vfs0090";
    #       rev = "3a5e27bc4e5dbbb42b953958796830e87b82d843";
    #       sha256 = "sha256-s6YPBeUYWBRUpVAsBvCKKTGQ8juMbPuJYWzXxKpcJkk=";
    #     };

    #     patches = prev.libfprint-2-tod1-vfs0090.patches ++ [
    #       # TODO remove once libfprint-tod is upgraded to a more recent version
    #       ./0003-vfs0090-adapt-to-old-libfprint-fpi-ssm-api.patch
    #     ];

    #     nativeBuildInputs = prev.libfprint-2-tod1-vfs0090.nativeBuildInputs ++ [ prev.python3 prev.python3Packages.wrapPython localPkgs.python-validity ];

    #     # postPatch = ''
    #     #   substituteInPlace ./gen_scan_matrix.py \
    #     #     --replace "calib_data_path" "${calibDataPath}"

    #     #   wrapPythonProgramsIn ./ ./
    #     # '';
    #   });
    # };

    packages = forAllSystems (system:
      import ./default.nix {
        pkgs = import nixpkgs {inherit system;};
      }
    );
  };
}
