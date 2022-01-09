{ config, pkgs, ... }:

{
  users.users.admin = {
    name = "admin";
    initialPassword = "1234";
    isNormalUser = true;
    extraGroups = [ "wheel" ];
    openssh.authorizedKeys.keys = [
      "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDHPBj2LARlTzFKHC0EohVEwQ+OctYSZkNGVwWdyhPOOWS/Ie9D/g5jZP9iym1SOVh4M/JHtpldeUIOJ2wcLvJkDC/Ijef4HYicBF86UGkWDLo+liYbKNRG+dOfncM4q51FuNjNz9j7W0tYxYBvVlkgB2+6G/Gp/ys9TMlcOvI22ChTetSRcmZ95KZdTDXoMe4NiyqddJE0GDNExPgvxbaNe7J2vmrh/heTlufFzu0W1PmTuMDNEq4whJ/DQEJbYOvXjK5qxlbu8Rl/j+zKJoj0bg9LPSAxloBEJ7VaGkmH2YxMHB7dijRNkuR28i8MvBFV4L6Jxi5PBVPk7yjuySD5 slim@hastromil-2013-06-11"
    ];
  };
  security.sudo.wheelNeedsPassword = false;
  nix.trustedUsers = [ "@wheel" ]; # https://github.com/serokell/deploy-rs/issues/25
}
