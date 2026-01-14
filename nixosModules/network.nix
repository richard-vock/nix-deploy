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
}
