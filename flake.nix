# Nix flake, see: https://nixos.org/manual/nix/unstable/command-ref/new-cli/nix3-flake.html
{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-24.11"; # Nix package repository
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
        name = "terminimal";
        src = pkgs.stdenv.mkDerivation {
          name = theme.name;
          src = zola-theme;
          installPhase = ''
            mkdir --parents $out/themes/${theme.name}
            cp --verbose --recursive . $out/themes/${theme.name}
          '';
        };
      };

      rustPlatform = pkgs.makeRustPlatform {
        cargo = pkgs.rust-bin.stable.latest.minimal;
        rustc = pkgs.rust-bin.stable.latest.minimal;
      };
    in {
      packages = {
        # `nix run .#serve`
        serve = pkgs.writeShellScriptBin "serve" "${pkgs.zola}/bin/zola serve --drafts";

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
            echo 'installing theme...'
            # Reset the file permissions since they'll be read-only from being in the Nix store.
            cp --recursive --no-preserve=mode "${theme.src}"/* .
          '';
          buildPhase = let
            version = pkgs.lib.strings.removeSuffix "-dirty" (self.rev or self.dirtyRev or "unknown");
          in ''
            echo 'adding version to `config.toml`'
            sed -i '/\[extra\]/a version = "${version}"' config.toml

            echo 'building website...'
            ${pkgs.zola}/bin/zola build

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
