{
  description = "VPS Infrastructure Deployment";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    netbird.url = "github:PatrickDaG/nixpkgs/fix-netbird";
    deploy-rs = {
      url = "github:serokell/deploy-rs";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    headscale.url = "github:juanfont/headscale";
  };

  outputs =
    inputs@{
      self,
      nixpkgs,
      deploy-rs,
      sops-nix,
      headscale,
      ...
    }:
    let
      system = "x86_64-linux";
      pkgs = nixpkgs.legacyPackages."${system}";
      mkSystem =
        name:
        nixpkgs.lib.nixosSystem {
          inherit system;
          specialArgs = inputs;
          modules = [
            sops-nix.nixosModules.sops
            headscale.nixosModules.default
            ./modules.nix
            ./${name}/default.nix
            ./${name}/hardware-configuration.nix
          ];
        };
    in
    {
      nixosConfigurations = nixpkgs.lib.attrsets.mergeAttrsList [
        { damogran = mkSystem "damogran"; }
      ];

      # nixosModules = {
      #   haproxy = ./modules/haproxy.nix;
      # };

      devShells."${system}".default = pkgs.mkShell {
        packages = [
          deploy-rs.packages."${system}".default
          pkgs.sops
          (pkgs.writeShellScriptBin "deploy-diff" ''
            #!${pkgs.bash}/bin/bash
            host=$2
            if [ -z "$host" ]; then
              host=$1
            fi
            set -eou pipefail

            trap 'rm wait.fifo' EXIT
            mkfifo wait.fifo

            deploy --debug-logs --dry-activate ".#$1" 2>&1 \
              | tee >(grep -v DEBUG) >(grep 'activate-rs --debug-logs activate' | \
                  sed -e 's/^.*activate-rs --debug-logs activate \(.*\) --profile-user.*$/\1/' | \
                  xargs -I% bash -xc "ssh $host 'nix store diff-closures /run/current-system %'" | \
                  grep '→' ; echo >wait.fifo) \
              >/dev/null

            read <wait.fifo
          '')
        ];
      };

      deploy.nodes = {
        damogran = {
          sshUser = "root";
          hostname = "damogran";
          profiles.system = {
            user = "root";
            path = deploy-rs.lib."${system}".activate.nixos self.nixosConfigurations.damogran;
          };
        };
      };

      checks = builtins.mapAttrs (system: deployLib: deployLib.deployChecks self.deploy) deploy-rs.lib;
    };
}
