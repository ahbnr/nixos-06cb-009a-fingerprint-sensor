{config, pkgs, lib, ...}:

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
    systemd.packages = [ pkgs.python-validity ];
  }
}
