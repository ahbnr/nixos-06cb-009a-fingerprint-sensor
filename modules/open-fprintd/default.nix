{config, lib, pkgs, ...}:

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
    environment.systemPackages = [ pkgs.fprintd ];

    systemd.packages = [ pkgs.open-fprintd ];

    # need to register the dbus configuration files of the package, otherwise we will get access errors
    services.dbus.packages = [ pkgs.open-fprintd ];

    # disable fprintd, since we are replacing it with open-fprintd and we are only adding the tooling of fprintd to the system packages
    services.fprintd.enable = false;
  };
}
