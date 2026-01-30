{
  config,
  lib,
  pkgs,
  domain,
  server,
  ...
}:

let
  cfg = config.database;
in
with lib;
{
  options.database = mkOption {
    type = types.attrsOf (
      types.submodule {
        options = {
          superuser = mkOption {
            type = types.bool;
            default = false;
          };
        };
      }
    );
    default = { };
  };

  config = mkIf (builtins.attrNames cfg != [ ]) {
    services.postgresql = {
      enable = true;
      package = pkgs.postgresql_16;
      ensureDatabases = builtins.attrNames cfg;
      ensureUsers = attrsets.mapAttrsToList (name: opts: {
        inherit name;
        ensureDBOwnership = true;
        ensureClauses = {
          login = true;
          superuser = opts.superuser;
        };
      }) cfg;
    };

    sops.secrets."postgres/users" = { };

    systemd.services.postgresql-set-passwords = {
      description = "Set PostgreSQL user passwords";
      after = [ "postgresql.service" ];
      requires = [ "postgresql.service" ];
      wantedBy = [ "postgresql.service" ];
      partOf = [ "postgresql.service" ];
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
      };
      script = ''
        ${pkgs.bash}/bin/bash -x ${../scripts/set_postgres_passwords.sh} ${pkgs.sudo}/bin/sudo
      '';
    };

    # TODO: set up backups

    # services.postgresqlBackup = {
    #   enable = true;
    #   startAt = "*-*-* 23:00:00";
    # };
    #
    # services.borgbackup.jobs.postgresql = import ../backup.nix domain server "postgresql" {
    #   paths = [ "/var/backup/postgresql" ];
    # };
  };
}
