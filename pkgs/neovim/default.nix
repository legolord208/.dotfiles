{ pkgs, lib, inputs, ... }:

with lib;
let
  ranger-vim2 = pkgs.vimUtils.buildVimPlugin {
    pname = "ranger-vim";
    version = "2019-10-30";
    src = pkgs.fetchFromGitHub {
      owner = "francoiscabrol";
      repo = "ranger.vim";
      rev = "91e82debdf566dfaf47df3aef0a5fd823cedf41c";
      sha256 = "sha256-6ut7u6AwtyYbHLHa2jelf5PkbtlfHvuHfWRL5z1CTUQ=";
    };
  };

  vim-argumentative = pkgs.vimUtils.buildVimPlugin {
    pname = "vim-argumentative";
    version = "2014-11-24";
    src = pkgs.fetchFromGitHub {
      owner = "PeterRincker";
      repo = "vim-argumentative";
      rev = "63a5f7deb675c38126de626f4c00e000902462fe";
      sha256 = "sha256-cgcNlsmEhZ8aWicJKgpnVJRl7nrMllFRDkXBhwBv7xk=";
    };
  };

  neovim-unwrapped = pkgs.wrapNeovim
    (pkgs.neovim-unwrapped.overrideAttrs (attrs: {
      version = "nightly";
      src = inputs.neovim-nightly;

      buildInputs = attrs.buildInputs ++ (with pkgs; [ tree-sitter ]);
    }))
    { };

  runtimeDeps = with pkgs; [
    # Need C compiler for nvim-treesitter
    gcc

    # For fzf
    bat
    fd
    fzf
    ripgrep

    # For ranger
    ranger
  ];

  self = pkgs.symlinkJoin {
    name = "nvim";

    paths = [ neovim pkgs.neovim-remote ];

    nativeBuildInputs = [ pkgs.makeWrapper ];

    postBuild = ''
      # Wrap neovim
      rm "$out/bin/nvim"
      makeWrapper "${neovim}/bin/nvim" "$out/bin/nvim" --prefix PATH : "${makeBinPath runtimeDeps}"

      # Alias neovim-remote as "e" (for edit)
      makeWrapper "${pkgs.neovim-remote}/bin/nvr" "$out/bin/e" --add-flags -s

      # Alias neovim-remote as "e-wait" (for edit wait)
      makeWrapper "${pkgs.neovim-remote}/bin/nvr" "$out/bin/e-wait" --add-flags "-s --remote-tab-wait"
    '';
  };

  neovim = neovim-unwrapped.override {
    configure = {
      customRC = ''
        source ${./.}/init.vim
      '';

      packages.nixPackages = with pkgs.vimPlugins; {
        # Required packages
        start = [
          # Dependencies
          nvim-yarp # ncm2

          # Libraries
          vim-operator-user

          # Style
          dracula-vim
          vim-airline
          vim-airline-themes

          # Navigation
          fzf-vim
          nerdtree
          ranger-vim2
          vim-rooter

          # VCS
          fugitive

          # Editing
          auto-pairs
          editorconfig-vim
          ncm2
          ncm2-bufword
          ncm2-path
          ncm2-syntax
          ncm2-ultisnips
          neoformat
          nvim-treesitter
          tabular
          ultisnips
          vim-argumentative
          vim-commentary
          vim-exchange
          vim-repeat
          vim-surround
          vim-table-mode

          # Validation
          LanguageClient-neovim

          # Languages
          vim-nix
          vim-toml
          vim-markdown
        ];

        # Packages that might be lazy-loaded
        # with :packadd <name>
        opt = [ ];
      };
    };
  };
in
self