{ config, ... }:
{
  sops.secrets."pangolin/env".restartUnits = [ "pangolin.service" ];

  services.pangolin = {
    enable = true;
    openFirewall = true;
    letsEncryptEmail = "dmrzl@mailbox.org";
    baseDomain = "damogran.cc";
    environmentFile = config.sops.secrets."pangolin/env".path;
  };
}
