{config, lib, localPackages, ...}:

let
  cfg = config.services.open-fprintd;
in

with lib;

{
  options = {
    services.open-fprintd = {
      enable = mkOption {
        default = false;
        type = with types; bool;
      };
    };
  };

  config = mkIf cfg.enable {
    environment.systemPackages = [ localPackages.fprintd-clients ];

    systemd.packages = [ localPackages.open-fprintd ];

    # need to register the dbus configuration files of the package, otherwise we will get access errors
    services.dbus.packages = [ localPackages.open-fprintd ];

    # disable fprintd, since we are replacing it with open-fprintd and we are using the user executable of fprintd-clients
    services.fprintd.enable = false;
  };
}
