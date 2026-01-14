{
  lib,
  ...
}:

{
  networking = {
    firewall = {
      enable = true;
      allowedTCPPorts = [ 55522 ];
      allowedUDPPorts = [ 55522 ];
    };
  };

  services.openssh = {
    enable = true;
    ports = [ 55522 ];
    settings = {
      PasswordAuthentication = false;
      PermitRootLogin = lib.mkForce "no";
    };
  };

  services.fail2ban = {
    enable = true;
    # ensure the sshd jail watches our custom SSH port
    jails.sshd.settings = {
      enabled = true;
      filter = "sshd";
      port = "55522";
    };
  };
}
