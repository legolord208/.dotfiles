{
  description = "My personal dotfiles and configurations";

  inputs = {
    nur = {
      type = "path";
      path = "./nur-packages";
    };

    emacs-overlay.url = "github:nix-community/emacs-overlay";
    nixops.url = "nixops";
    nixops-digitalocean = {
      url = "github:nix-community/nixops-digitalocean";
      flake = false;
    };
  };

  outputs = { self, nixpkgs, nur, emacs-overlay, nixops, nixops-digitalocean } @ inputs: let
    forAllSystems = nixpkgs.lib.genAttrs [ "x86_64-linux" ];
  in {
    overlay = final: prev: (
      builtins.foldl' (a: b: a // b) {} (
        map
          (overlay: overlay final prev)
          self.overlays
      )
    );
    overlays =
      [ emacs-overlay.overlay ]
      ++ (
        map
          (name: import (./overlays + "/${name}"))
          (builtins.attrNames (builtins.readDir ./overlays))
      );

    packages = forAllSystems (system: let
      shared = nixpkgs.legacyPackages."${system}".callPackage ./shared {};
      sharedBase = ./shared/base.nix;

      mkNixosConfig = config: nixpkgs.lib.nixosSystem {
        inherit system;
        modules = [
          # Base packages
          nur.nixosModules.programs
          ./shared/base.nix

          # Config
          config
        ];
        extraArgs = inputs // {
          inherit self shared sharedBase;
        };
      };
    in {
      # NixOS configurations
      nixosConfigurations = {
        samuel-computer = mkNixosConfig ./etc/computer/configuration.nix;
        samuel-laptop = mkNixosConfig ./etc/laptop/configuration.nix;
      };

      # Packages
      nixops = nixops.packages."${system}".nixops.overridePythonAttrs (attrs: {
        propagatedBuildInputs = attrs.propagatedBuildInputs ++ [
          (nixpkgs.legacyPackages."${system}".callPackage nixops-digitalocean {})
        ];
      });
    });

    nixopsConfigurations.default = {
      network.description = "My personal VPS network";
      resources.sshKeyPairs.ssh-key = {};

      inherit nixpkgs;

      main = import ./servers/main;
    };
  };
}
