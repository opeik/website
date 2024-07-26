# Nix flake, see: https://nixos.org/manual/nix/unstable/command-ref/new-cli/nix3-flake.html
{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable"; # Nix package repository
    utils.url = "github:numtide/flake-utils"; # Flake utility functions
    rust-overlay.url = "github:oxalica/rust-overlay";
    # Zola theme.
    zola-theme = {
      url = "github:opeik/zola-theme-terminimal";
      flake = false;
    };
  };

  outputs = {
    self,
    nixpkgs,
    utils,
    zola-theme,
    rust-overlay,
  }:
    utils.lib.eachDefaultSystem (system: let
      pkgs = import nixpkgs {
        inherit system;
        overlays = [(import rust-overlay)];
      };
      theme = pkgs.stdenv.mkDerivation {
        name = "zola-theme-terminimal";
        src = zola-theme;
        installPhase = "cp --verbose --recursive . $out";
      };
      themeName = pkgs.lib.toLower ((builtins.fromTOML (builtins.readFile "${theme}/theme.toml")).name);
      rustPlatform = pkgs.makeRustPlatform {
        cargo = pkgs.rust-bin.stable.latest.minimal;
        rustc = pkgs.rust-bin.stable.latest.minimal;
      };
      zola-19 = pkgs.zola.override (old: {
        rustPlatform =
          old.rustPlatform
          // {
            buildRustPackage = args:
              rustPlatform.buildRustPackage (args
                // {
                  version = "0.19.1";
                  src = builtins.fetchGit {
                    url = "https://github.com/getzola/zola";
                    ref = "refs/tags/v0.19.1";
                    rev = "041da029eedbca30c195bc9cd8c1acf89b4f60c0";
                  };
                  cargoHash = "sha256-Q2Zx00Gf89TJcsOFqkq0b4e96clv/CLQE51gGONZZl0=";
                });
          };
      });
    in {
      packages = {
        # `nix run .#serve`
        serve = pkgs.writeShellScriptBin "serve" "${zola-19}/bin/zola serve --drafts";

        # `nix build .#website`
        website = pkgs.stdenv.mkDerivation {
          name = "website";
          # Only include the zola relevant files to reduce frivolous rebuilds.
          src = builtins.path {
            path = ./.;
            name = "website-src";
            # filter = path: type:
            #   (
            #     x:
            #       builtins.any (file: pkgs.lib.hasSuffix file x) ["config.toml"]
            #       || builtins.any (dir: pkgs.lib.hasInfix dir x) ["content" "static" "templates"]
            #   )
            #   path;
          };
          buildInputs = with pkgs; [zola-19 nodePackages_latest.prettier];
          configurePhase = ''
            echo 'adding theme to `themes`...'
            mkdir --parents themes
            cp --recursive ${theme} themes/${themeName}

            echo 'sources:'
            ${pkgs.tree}/bin/tree .
          '';
          buildPhase = let
            version = pkgs.lib.strings.removeSuffix "-dirty" (self.rev or self.dirtyRev or "unknown");
          in ''
            echo 'adding version to `config.toml`'
            sed -i '/\[extra\]/a version = "${version}"' config.toml

            echo 'building website...'
            zola build

            echo 'formatting output...'
            prettier --log-level debug --bracket-same-line true --write public

            echo 'stripping empty lines from output html...'
            find public -print -type f -name '*.html' -exec sed -i '/^$/d' {} +
          '';
          installPhase = "cp --recursive public $out";
        };
      };

      # `nix develop`
      devShell = pkgs.mkShell {
        buildInputs = [
          zola-19
          self.formatter.${system}
        ];
        shellHook = ''
          mkdir --parents themes
          # ln --symbolic --force --no-dereference ${theme} themes/${themeName}
        '';
      };

      # `nix fmt`
      formatter = pkgs.alejandra;
    });
}
