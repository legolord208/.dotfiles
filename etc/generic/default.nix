# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ config, lib, pkgs, shared, ... }:

let
  cfg = config.setup;
in {
  options.setup = with lib; {
    name = mkOption {
      type = types.nullOr types.str;
      description = "The name of this deployment";
      default = null;
    };
    full = mkOption {
      type = types.bool;
      default = false;
      description = "Installs all the bells and whistles. Just an alias for enabling different components.";
    };
  };

  imports = [
    # Files
    ./containers.nix
    ./gui
    ./hardware.nix
    ./home.nix
    ./meta.nix
    ./packages
    ./services.nix
    ./sudo.nix
  ];

  config = {
    setup = lib.mkIf cfg.full {
      boot = true;
      network = true;

      graphics.enable = true;

      packages = {
        languages = {
          c = true;
          elm = true;
          go = true;
          haskell = true;
          java = true;
          latex = true;
          markdown = true;
          python = true;
          rust = true;
          wasm = true;
        };
      };
    };

    # Specify hostname, if set
    networking = lib.mkIf (cfg.name != null) {
      hostName = "samuel-${cfg.name}";
    };

    # Enable SYSRQ keys because disabling that is a horrible idea I think
    boot.kernel.sysctl."kernel.sysrq" = 1;

    # Misc. settings
    documentation.dev.enable  = true;
    hardware.bluetooth.enable = true;
    time.hardwareClockInLocalTime = true; # fuck windows

    # Mime type for wasm, see https://github.com/mdn/webassembly-examples/issues/5
    environment.etc."mime.types".text = ''
      application/wasm  wasm
    '';

    # User settings
    users.users."${shared.consts.user}" = {
      initialPassword = "nixos";
      isNormalUser    = true;
      extraGroups     = [ "libvirtd" "adbusers" ];
    };

    # Unlock GnuPG automagically
    security.pam.services.login.gnupg = {
      enable = true;
      noAutostart = true;
      storeOnly = true;
    };

    # This value determines the NixOS release with which your system is to be
    # compatible, in order to avoid breaking some software such as database
    # servers. You should change this only after NixOS release notes say you
    # should.
    system.stateVersion = "18.03"; # Did you read the comment?
  };
}
