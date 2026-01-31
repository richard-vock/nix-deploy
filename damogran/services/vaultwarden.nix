{
  config,
  domain,
  ...
}:
{
  services.vaultwarden = {
    enable = true;
    environmentFile = config.sops.secrets."vaultwarden/env".path;
    backupDir = "/data/vaultwarden";
    config = {
      SIGNUPS_ALLOWED = false;
      DOMAIN = "https://bitwarden.${domain}";
      SHOW_PASSWORD_HINT = false;
      ROCKET_ADDRESS = "127.0.0.1";
      ROCKET_PORT = 8222;
      ROCKET_LOG = "critical";
    };
  };

  ingress.vaultwarden = {
    subdomain = "bitwarden";
    port = 8222;
    tailscaleOnly = true;
  };

  # services.borgbackup.jobs.vaultwarden = import ../../backup.nix domain server "vaultwarden" {
  #   paths = [ "/var/backup/vaultwarden" ];
  # };

  sops.secrets."vaultwarden/env" = {
    owner = "vaultwarden";
  };
}
