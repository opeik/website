# Nix flake, see: https://nixos.org/manual/nix/unstable/command-ref/new-cli/nix3-flake.html
{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-24.05"; # Nix package repository
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

      # Our zola theme!
      theme = {
        name = pkgs.lib.toLower ((builtins.fromTOML (builtins.readFile "${theme.src}/theme.toml")).name);
        src = pkgs.stdenv.mkDerivation {
          name = "zola-theme-terminimal";
          src = zola-theme;
          installPhase = "cp --verbose --recursive . $out";
        };
      };

      rustPlatform = pkgs.makeRustPlatform {
        cargo = pkgs.rust-bin.stable.latest.minimal;
        rustc = pkgs.rust-bin.stable.latest.minimal;
      };

      # Zola is outdated in nixpkgs, build it ourself.
      zola = pkgs.zola.override (old: {
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
        serve = pkgs.writeShellScriptBin "serve" "${zola}/bin/zola serve --drafts";

        # `nix build .#website`
        website = pkgs.stdenv.mkDerivation {
          name = "website";
          src = builtins.path {
            path = ./.;
            name = "website-src";
            # Only include files which can affect the website output to prevent frivolous rebuilds.
            filter = path: type:
              (
                x:
                  builtins.any (file: pkgs.lib.hasSuffix file x) ["config.toml"]
                  || builtins.any (dir: pkgs.lib.hasInfix dir x) ["content" "static" "templates"]
              )
              path;
          };
          configurePhase = ''
            echo 'adding theme to `themes`...'
            mkdir --parents themes
            # Reset the file permissions since they'll be read-only from being in the Nix store.
            cp --recursive --no-preserve=mode ${theme.src} themes/${theme.name}

            echo 'sources:'
            ${pkgs.tree}/bin/tree .
          '';
          buildPhase = let
            version = pkgs.lib.strings.removeSuffix "-dirty" (self.rev or self.dirtyRev or "unknown");
          in ''
            echo 'adding version to `config.toml`'
            sed -i '/\[extra\]/a version = "${version}"' config.toml

            echo 'building website...'
            ${zola}/bin/zola build

            ${pkgs.tree}/bin/tree public
            echo 'formatting output...'
            ${pkgs.nodePackages_latest.prettier}/bin/prettier --bracket-same-line true --write public

            echo 'stripping empty lines from output html...'
            find public -type f -name '*.html' -printf 'stripped file: %p\n' -exec sed -i '/^$/d' {} +
          '';
          installPhase = "cp --recursive public $out";
        };
      };

      # `nix develop`
      devShell = pkgs.mkShell {
        buildInputs = [
          zola
          self.formatter.${system}
        ];
        shellHook = ''
          mkdir --parents themes
          # ln --symbolic --force --no-dereference ${theme.src} themes/${theme.name}
        '';
      };

      # `nix fmt`
      formatter = pkgs.alejandra;
    });
}
