{ config, pkgs, ... }:
{
  sops.secrets."users/admin/id_ed25519_main_pub" = {
    path = "/home/admin/.ssh/id_ed25519_main.pub";
    owner = "admin";
    group = "users";
    mode = "0600";
  };
  sops.secrets."users/admin/id_ed25519_main" = {
    path = "/home/admin/.ssh/id_ed25519_main";
    owner = "admin";
    group = "users";
    mode = "0600";
  };
  sops.secrets."users/admin/pw" = {
    neededForUsers = true;
  };

  users.users.admin = {
    name = "admin";
    hashedPasswordFile = config.sops.secrets."users/admin/pw".path;
    isNormalUser = true;
    extraGroups = [ "wheel" ];
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIBOipqKXXn3zmGmkXTucbZH3JDuJB+99G6hRByUuZvnk rvock@mailbox.org"
    ];
  };
  # security.sudo.wheelNeedsPassword = false;
  nix.settings."trusted-users" = [ "@wheel" ]; # https://github.com/serokell/deploy-rs/issues/25
}
