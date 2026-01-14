{
  pkgs,
  inputs,
  ...
}:

{
  time.timeZone = "UTC";
  nix = {
    package = pkgs.nix;

    extraOptions = ''
      experimental-features = nix-command flakes
    '';

    generateNixPathFromInputs = true;
    linkInputs = true;
    generateRegistryFromInputs = true;
  };

  nixpkgs.config = {
    allowUnfree = true;
  };

  sops.defaultSopsFile = ../secrets/secrets.yaml;
  sops.age.keyFile = "/var/lib/sops-nix/deploy.age";
  sops.age.sshKeyPaths = [ ];
  sops.age.generateKey = false;

  # Set the system revision to the flake revision
  # You can query this value with: $ nix-info -m
  system.configurationRevision = (if inputs.self ? rev then inputs.self.rev else null);

  system.stateVersion = "22.11";
}
