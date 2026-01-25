{
  imports = [
    ./settings.nix
    ./modules/postgres.nix
    ./modules/reverse-proxy.nix
    ./modules/authentik.nix
  ];
}
