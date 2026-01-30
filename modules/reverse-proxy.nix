{
  config,
  lib,
  domain,
  email,
  ...
}:

let
  ingresses = config.ingress;

  mkVirtualHost =
    name: ingress:
    let
      hostName =
        if ingress.host != null then ingress.host else "${ingress.subdomain}.${domain}";
      upstream = "http://${ingress.address}:${builtins.toString ingress.port}";
      tlsEnabled = ingress.letsencrypt || ingress.sslCertificate != null;
      tailscaleRestriction = lib.optionalString ingress.tailscaleOnly ''
        allow 100.64.0.0/10;
        allow fd7a:115c:a1e0::/48;
        deny all;
      '';
    in
    {
      name = hostName;
      value =
        let
          manualTlsAttrs = lib.optionalAttrs (ingress.sslCertificate != null) {
            sslCertificate = ingress.sslCertificate;
            sslCertificateKey = ingress.sslCertificateKey;
          };
        in
        {
          enableACME = ingress.letsencrypt;
          forceSSL = tlsEnabled;
          addSSL = tlsEnabled;
          extraConfig = lib.mkIf (tailscaleRestriction != "") tailscaleRestriction;
          locations."/" = {
            proxyPass = upstream;
            proxyWebsockets = true;
          };
        }
        // manualTlsAttrs;
    };

  needsAcme = lib.any (ingress: ingress.letsencrypt) (lib.attrValues ingresses);
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

            sslCertificate = mkOption {
              type = types.nullOr types.str;
              default = null;
              description = "Path to an existing TLS certificate to use instead of Let's Encrypt.";
            };

            sslCertificateKey = mkOption {
              type = types.nullOr types.str;
              default = null;
              description = "Path to the private key that matches sslCertificate.";
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
      assertions = mapAttrsToList (
        name: ingress:
        {
          assertion = (ingress.sslCertificate == null) == (ingress.sslCertificateKey == null);
          message = "Ingress " + name + " must set both sslCertificate and sslCertificateKey or neither.";
        }
      ) ingresses;
    }

    {
      services.nginx = {
        enable = true;
        recommendedProxySettings = true;
        recommendedTlsSettings = true;
        recommendedGzipSettings = true;
        virtualHosts = builtins.listToAttrs (mapAttrsToList mkVirtualHost ingresses);
      };
    }

    (mkIf needsAcme {
      security.acme = {
        acceptTerms = true;
        defaults.email = email;
      };
    })

  ];
}
