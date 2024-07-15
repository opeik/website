# Nix flake, see: https://nixos.org/manual/nix/unstable/command-ref/new-cli/nix3-flake.html
{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable"; # Nix package repository
    utils.url = "github:numtide/flake-utils"; # Flake utility functions
    # Zola theme.
    zola-theme = {
      url = "github:pawroman/zola-theme-terminimal";
      flake = false;
    };
  };

  outputs = {
    self,
    nixpkgs,
    utils,
    zola-theme,
  }:
    utils.lib.eachDefaultSystem (system: let
      pkgs = nixpkgs.legacyPackages.${system};
      theme = pkgs.stdenv.mkDerivation {
        name = "zola-theme-terminimal";
        src = zola-theme;
        patchPhase = ''
          substituteInPlace sass/color/pink.scss --replace '238,114,241' '171,158,239'
          echo "@import 'mods';" >> sass/style.scss
          cp ${./styles/mods.scss} sass/mods.scss
        '';
        installPhase = "cp -R . $out";
      };
      themeName = pkgs.lib.toLower ((builtins.fromTOML (builtins.readFile "${theme}/theme.toml")).name);
    in {
      packages = {
        # `nix run .#serve`
        serve = pkgs.writeShellScriptBin "serve" "${pkgs.zola}/bin/zola serve --drafts";

        # `nix build .#website`
        website = pkgs.stdenv.mkDerivation {
          name = "website";
          # Only include the zola relevant files to reduce frivolous rebuilds.
          src = builtins.path {
            path = ./.;
            name = "website-src";
            filter = path: type:
              (
                x:
                  builtins.any (file: pkgs.lib.hasSuffix file x) ["config.toml"]
                  || builtins.any (dir: pkgs.lib.hasInfix dir x) ["content" "static" "templates" "styles"]
              )
              path;
          };
          buildInputs = with pkgs; [zola nodePackages_latest.prettier];
          configurePhase = ''
            mkdir --parents themes
            ln --symbolic ${theme} themes/${themeName}
          '';
          buildPhase = let
            version = pkgs.lib.strings.removeSuffix "-dirty" (self.rev or self.dirtyRev or "unknown");
          in ''
            # Add git revision to the config for inclusion in the footers.
            sed -i '/\[extra\]/a version = "${version}"' config.toml

            # Build the website!
            zola build

            # Format the output for ease of debugging.
            prettier --bracket-same-line true --write public

            # Templates tend to create a lot of empty lines, strip them.
            find public -type f -name '*.html' -exec sed -i '/^$/d' {} +
          '';
          installPhase = "cp --recursive public $out";
        };
      };

      # `nix develop`
      devShell = pkgs.mkShell {
        buildInputs = with pkgs; [
          zola
          self.formatter.${system}
        ];
        shellHook = ''
          mkdir --parents themes
          ln --symbolic --force --no-dereference ${theme} themes/${themeName}
        '';
      };

      # `nix fmt`
      formatter = pkgs.alejandra;
    });
}
