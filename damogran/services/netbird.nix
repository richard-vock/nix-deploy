{
  pkgs,
  lib,
  config,
  domain,
  utils,
  netbird,
  ...
}:
let
  netbird_domain = "netbird.${domain}";
  client_id = "gsjm5ep3YKcUaBk0xCAm6xK9GwoJbywlHEAdytLk";
in
{
  disabledModules = [
    "services/networking/netbird/server.nix"
    "services/networking/netbird/signal.nix"
    "services/networking/netbird/management.nix"
    "services/networking/netbird/dashboard.nix"
    "services/networking/netbird/coturn.nix"
  ];

  imports = [
    "${netbird}/nixos/modules/services/networking/netbird/server.nix"
  ];

  documentation.nixos.enable = false;

  services.netbird.enable = true;

  users.users.netbird = {
    name = "netbird";
    group = "netbird";
    isSystemUser = true;
  };
  users.groups.netbird = { };

  sops.secrets = {
    # netbird_authentik_password.owner = "netbird";
    # turn_secret.owner = "netbird";
    "netbird/authentik-secret".owner = "netbird";
    "netbird/relay-secret".owner = "netbird";
    "netbird/datastore-key".owner = "netbird";
    "netbird/turn-secret" = {
      owner = "turnserver";
      group = "netbird";
      mode = "0440";
    };
  };

  # ingress.netbird = {
  #   subdomain = "netbird";
  #   port = 8080;
  # };

  # services.nginx.defaultListen = [
  #   {
  #     addr = "127.0.0.1";
  #     port = 8080;
  #     proxyProtocol = true;
  #   }
  # ];

  # services.nginx.virtualHosts."${netbird_domain}" = {
  #   locations."/" = lib.mkForce {
  #     root = config.services.netbird.server.dashboard.finalDrv;
  #     tryFiles = "$uri $uri.html $uri/ =404";
  #   };
  #   forceSSL = false;
  # };
  #
  # systemd.services.netbird-relay.script =
  #   let
  #     cfg = config.services.netbird.server.relay;
  #   in
  #   lib.mkForce ''
  #     export NB_AUTH_SECRET="$(<${cfg.authSecretFile})"
  #     ${lib.getExe' cfg.package "netbird-relay"} -H 127.0.0.1:9400
  #   '';

  services.netbird.server = {
    enable = true;
    domain = netbird_domain;

    relay = {
      enable = true;
      authSecretFile = config.sops.secrets."netbird/relay-secret".path;
      package = pkgs.netbird-relay;
      settings = {
        NB_EXPOSED_ADDRESS = "rels://netbird.damogran.cc:443/relay";
      };
    };
    signal = {
      port = 10000;
    };
    proxy = {
      domain = netbird_domain;
      enableNginx = false;
      managementAddress = "[::1]:10001";
      signalAddress = "[::1]:10000";
      relayAddress = "[::1]:33080";
    };

    management = {
      port = 10001;
      singleAccountModeDomain = "net.${domain}";
      dnsDomain = "net.${domain}";

      oidcConfigEndpoint = "https://authentik.${domain}/application/o/netbird/.well-known/openid-configuration";
      settings = {
        TURNConfig = {
          #       Turns = [
          #         {
          #           Proto = "udp";
          #           URI = "turn:${netbird_domain}:3478";
          #           Username = "netbird";
          #           Password._secret = config.sops.secrets."netbird/turn-secret".path;
          #         }
          #       ];
          Secret._secret = config.sops.secrets."netbird/turn-secret".path;
        };
        Signal.URI = "${netbird_domain}:443";
        #     #     IdpManagerConfig = {
        #     #       ManagerType = "authentik";
        #     #       ClientConfig = {
        #     #         Issuer = "https://authentik.${domain}/application/o/netbird/";
        #     #         ClientID = client_id;
        #     #         TokenEndpoint = "https://authentik.${domain}/application/o/token/";
        #     #         ClientSecret = "";
        #     #       };
        #     #       ExtraConfig = {
        #     #         Password._secret = "/run/secrets/netbird_authentik_password";
        #     #         Username = "netbird";
        #     #       };
        #     #     };
        #     #
        #     HttpConfig = {
        #       AuthAudience = client_id;
        #       AuthUserIDClaim = "sub";
        #     };
        #
        #     PKCEAuthorizationFlow.ProviderConfig = {
        #       Audience = client_id;
        #       ClientID = client_id;
        #       ClientSecret = "";
        #       AuthorizationEndpoint = "https://authentik.${domain}/application/o/authorize/";
        #       TokenEndpoint = "https://authentik.${domain}/application/o/token/";
        #       RedirectURLs = [ "http://localhost:53000" ];
        #     };
        DataStoreEncryptionKey._secret = config.sops.secrets."netbird/datastore-key".path;
        PprofEnabled = false;
      };
    };

    coturn = {
      enable = true;
      passwordFile = config.sops.secrets."netbird/turn-secret".path;
    };
    #
    dashboard = {
      enableNginx = true;
      domain = "localhost";
      package = pkgs.netbird-dashboard;
      settings = {
        AUTH_AUTHORITY = "https://authentik.${domain}/application/o/netbird/";
        AUTH_SUPPORTED_SCOPES = "openid profile email offline_access api";
        AUTH_AUDIENCE = client_id;
        AUTH_CLIENT_ID = client_id;
      };
    };
  };

  systemd.services.netbird-management = {
    after = [
      "authentik-server.service"
      "authentik-worker.service"
    ];
    requires = [ "authentik-server.service" ];
    wants = [ "authentik-worker.service" ];
  };
}
