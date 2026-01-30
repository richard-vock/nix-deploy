{ domain, pkgs, ... }:
{
  imports = [
    # ./services/vaultwarden.nix
    # ./services/tandoor.nix
    ./services/authentik.nix
    ./services/headscale.nix
    ./services/tailscale.nix
    # ./services/borgbackup.nix
    ../users.nix
  ];

  _module.args.server = "damogran";

  security.sudo.configFile = ''
    Defaults:root,%wheel env_keep+=LOCALE_ARCHIVE
    Defaults:root,%wheel env_keep+=NIX_PATH
    Defaults lecture = never
  '';

  services.openssh = {
    enable = true;
    ports = [ 55522 ];
    settings = {
      PasswordAuthentication = false;
      # PermitRootLogin = lib.mkForce "yes";
    };
  };

  services.fail2ban = {
    enable = true;
    jails.sshd.settings = {
      enabled = true;
      filter = "sshd";
      port = "55522";
    };
  };

  services.resolved.enable = true;
  networking = {
    nameservers = [
      "1.1.1.1#one.one.one.one"
      "1.0.0.1#one.one.one.one"
    ];
    hostName = "damogran";
    domain = domain;
    firewall = {
      enable = true;
      allowedTCPPorts = [
        80
        443
        55522
      ];
      allowedUDPPorts = [ 55522 ];
    };

  };

  nix.settings."trusted-users" = [
    "root"
    "@wheel"
  ];

  sops.defaultSopsFile = ../secrets/damogran.yaml;
  sops.age.keyFile = "/var/lib/sops-nix/deploy.age";
  sops.age.sshKeyPaths = [ ];
  sops.age.generateKey = false;

  environment.systemPackages = with pkgs; [
    neovim
    tmux
  ];

  # The NixOS release to be compatible with for stateful data such as databases.
  system.stateVersion = "22.11";
}
