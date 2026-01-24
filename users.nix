{ config, ... }:
let
  key = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIBOipqKXXn3zmGmkXTucbZH3JDuJB+99G6hRByUuZvnk rvock@mailbox.org";
in
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

  users.users.root.openssh.authorizedKeys.keys = [ key ];

  users.users.admin = {
    name = "admin";
    group = "users";
    hashedPasswordFile = config.sops.secrets."users/admin/pw".path;
    isNormalUser = true;
    createHome = true;
    extraGroups = [ "wheel" ];
    openssh.authorizedKeys.keys = [ key ];
  };
}
