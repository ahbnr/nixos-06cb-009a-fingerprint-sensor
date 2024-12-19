{config, lib, libfprint-2-tod1-vfs0090-bingch, localPackages, ...}:

let
  cfg = config.services."06cb-009a-fingerprint-sensor";
in

with lib;

{
  imports = [
    (args: import ../python-validity (args // {localPackages = localPackages;}))
    ../open-fprintd
  ];

  options = {
    services."06cb-009a-fingerprint-sensor" = {
      enable = mkOption {
        default = false;
        type = with types; bool;
      };

      backend = mkOption {
        default = "python-validity";
        type = with types; enum [
          "python-validity"
          "libfprint-tod"
        ];
      };

      calib-data-file = mkOption {
        type = with types; path;
      };
    };
  };

  config = mkIf cfg.enable (
    let
      python-validity-mode = {
        services.open-fprintd.enable = true;
        services.python-validity.enable = true;
      };

      libfprint-tod-mode = {
        services.open-fprintd.enable = false;
        services.python-validity.enable = false;

        services.fprintd = {
          enable = true;
          tod = {
            enable = true;
            driver = libfprint-2-tod1-vfs0090-bingch {
              calib-data-file = cfg.calib-data-file;
            };
          };
        };
      };
    in
      mkMerge [
        (mkIf (cfg.backend == "python-validity") python-validity-mode)
        (mkIf (cfg.backend == "libfprint-tod") libfprint-tod-mode)
      ]
  );
}
