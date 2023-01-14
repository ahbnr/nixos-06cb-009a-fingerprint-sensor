{config, pkgs, lib, ...}:

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
    systemd.packages = [ pkgs.open-fprintd ];
  }
}
