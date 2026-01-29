{
  config,
  lib,
  domain,
  ...
}:
let
  headscaleDomain = "headscale.${domain}";
  magicDnsDomain = "net.${domain}";
  listenAddress = "127.0.0.1";
  listenPort = 8085;
in
{
  services.headscale = {
    enable = true;
    serverUrl = "https://${headscaleDomain}";
    address = listenAddress;
    port = listenPort;

    settings = {
      dns = {
        magic_dns = true;
        base_domain = magicDnsDomain;
        nameservers.global = [
          "1.1.1.1"
          "1.0.0.1"
        ];
      };
      logtail.enabled = false;
      oidc = {
        issuer = "https://authentik.${domain}/application/o/headscale/";
        client_id = "VzQA2VsUtmS85AzKXc6deBbiEWaRgrWs05m3dHrf";
        client_secret_path = config.sops.secrets."headscale/oidc-client-secret".path;
        scope = [
          "openid"
          "profile"
          "email"
        ];
        domain_map = {
          ".*" = "default"; # map every user to the default namespace
        };
      };
    };
  };

  ingress.headscale = {
    subdomain = "headscale";
    address = listenAddress;
    port = listenPort;
  };

  sops.secrets = {
    "headscale/oidc-client-secret" = { };
  };
}
