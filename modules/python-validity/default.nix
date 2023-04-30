{config, lib, localPackages, ...}:

let
  cfg = config.services.python-validity;
in

with lib;

{
  options = {
    services.python-validity = {
      enable = mkOption {
        default = false;
        type = with types; bool;
      };
    };
  };

  config = mkIf cfg.enable {
    environment.systemPackages = [
      localPackages.python-validity
    ];

    systemd.packages = [ localPackages.python-validity ];
    systemd.services.python3-validity.wantedBy = [ "multi-user.target" ];

    # need to register the dbus configuration files of the package, otherwise we will get access errors
    services.dbus.packages = [ localPackages.python-validity ];
  };
}
