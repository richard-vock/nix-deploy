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
  listenPort = 8180;
in
{
  services.headscale = {
    enable = true;
    serverUrl = "https://${headscaleDomain}";
    address = listenAddress;
    port = listenPort;

    dns = {
      nameservers = [
        "1.1.1.1"
        "1.0.0.1"
      ];
      magicDns = true;
      baseDomain = magicDnsDomain;
    };

    settings = {
      logtail = {
        enabled = false;
      };
    };
  };

  ingress.headscale = {
    subdomain = "headscale";
    address = listenAddress;
    port = listenPort;
  };
}
