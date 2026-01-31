{
  config,
  lib,
  pkgs,
  domain,
  email,
  ...
}:

let
  ingresses = config.ingress;

  mkVirtualHost =
    name: ingress:
    let
      hostName = if ingress.host != null then ingress.host else "${ingress.subdomain}.${domain}";
      upstream = "http://${ingress.address}:${builtins.toString ingress.port}";
      tailscaleRestriction = lib.optionalString ingress.tailscaleOnly ''
        allow 100.64.0.0/10;
        allow fd7a:115c:a1e0::/48;
        deny all;
      '';
    in
    {
      name = hostName;
      value = {
        forceSSL = true;
        extraConfig = lib.mkIf (tailscaleRestriction != "") tailscaleRestriction;
        locations."/" = {
          proxyPass = upstream;
          proxyWebsockets = true;
        };
        sslCertificate = "/var/lib/acme/${hostName}/fullchain.pem";
        sslCertificateKey = "/var/lib/acme/${hostName}/key.pem";
      };
    };
in
with lib;
{
  options.ingress = mkOption {
    type = types.attrsOf (
      types.submodule (
        { config, ... }:
        {
          options = {
            subdomain = mkOption {
              type = types.str;
              description = "Subdomain handled by the reverse proxy.";
            };

            host = mkOption {
              type = types.nullOr types.str;
              default = null;
              description = "Override the fully qualified host name (defaults to subdomain.${domain}).";
            };

            letsencrypt = mkOption {
              type = types.bool;
              default = true;
              description = "Request and use a Let's Encrypt certificate for this subdomain.";
            };

            address = mkOption {
              type = types.str;
              default = "127.0.0.1";
              description = "Address of the backend service.";
            };

            port = mkOption {
              type = types.port;
              default = 8080;
              description = "Port of the backend service.";
            };

            tailscaleOnly = mkOption {
              type = types.bool;
              default = false;
              description = "If true, allow only Tailscale address ranges (100.64.0.0/10 and fd7a:115c:a1e0::/48).";
            };
          };
        }
      )
    );

    default = { };
    description = "Simple reverse proxy mapping between subdomains and backend services.";
  };

  config = mkMerge [
    {
      services.nginx = {
        enable = true;
        recommendedProxySettings = true;
        recommendedTlsSettings = true;
        recommendedGzipSettings = true;
        virtualHosts = builtins.listToAttrs (mapAttrsToList mkVirtualHost ingresses);
      };
    }

    {
      # allow lego to configure acme by writing hetzner DNS entries
      security.acme = {
        acceptTerms = true;
        defaults = {
          email = "root@damogran.cc";
          dnsProvider = "cloudflare";
          environmentFile = config.sops.secrets."cloudflare/dns-api-token-env".path;
          dnsPropagationCheck = true;
        };
        certs = builtins.listToAttrs (
          mapAttrsToList (
            name: ingress:
            let
              hostName = if ingress.host != null then ingress.host else "${ingress.subdomain}.${domain}";
            in
            {
              name = hostName;
              value = {
                group = "nginx";
              };
            }
          ) ingresses
        );
      };
      sops.secrets."cloudflare/dns-api-token-env" = { };
    }

    {
      services.headscale.settings.dns.extra_records = mapAttrsToList (
        name: ingress:
        let
          hostName = if ingress.host != null then ingress.host else "${ingress.subdomain}.${domain}";
        in
        {
          name = hostName;
          type = "A";
          value = "100.64.0.1";
        }
      ) (filterAttrs (name: ingress: ingress.tailscaleOnly) ingresses);
    }
  ];
}
