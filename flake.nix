{
  description = "My server flake";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    flake-utils-plus.url = "github:gytis-ivaskevicius/flake-utils-plus";
    deploy-rs = {
      url = "github:serokell/deploy-rs";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    sops-nix.url = "github:Mic92/sops-nix";
  };

  outputs =
    inputs@{
      self,
      nixpkgs,
      flake-utils-plus,
      ...
    }:
    let
      nixosModules = flake-utils-plus.lib.exportModules (
        nixpkgs.lib.mapAttrsToList (name: value: ./nixosModules/${name}) (builtins.readDir ./nixosModules)
      );
    in
    flake-utils-plus.lib.mkFlake {
      inherit self inputs nixosModules;

      hosts = {
        hetzner.modules = with nixosModules; [
          inputs.sops-nix.nixosModules.sops
          common
          network
          admin
          hardware-hetzner
          # pangolin
          # docker
        ];
      };

      deploy.nodes = {
        damogran = {
          hostname = "46.224.43.253";
          fastConnection = false;
          profiles = {
            nexus = {
              sshUser = "admin";
              path = inputs.deploy-rs.lib.x86_64-linux.activate.nixos self.nixosConfigurations.hetzner;
              user = "root";
            };
          };
        };
      };

      outputsBuilder = (
        channels: {
          devShell = channels.nixpkgs.mkShell {
            name = "my-deploy-shell";
            buildInputs = with channels.nixpkgs; [
              nix
              inputs.deploy-rs.packages.${system}.deploy-rs
            ];
          };
        }
      );

      checks = builtins.mapAttrs (
        system: deployLib: deployLib.deployChecks self.deploy
      ) inputs.deploy-rs.lib;
    };
}
