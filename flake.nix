# Nix flake, see: <https://nixos.org/manual/nix/unstable/command-ref/new-cli/nix3-flake.html>
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
        patchPhase = "substituteInPlace sass/color/pink.scss --replace '238,114,241' '171,158,239'";
        installPhase = "cp -R . $out";
      };
      themeName = pkgs.lib.toLower ((builtins.fromTOML (builtins.readFile "${theme}/theme.toml")).name);
    in
      with pkgs; {
        # `nix build`
        defaultPackage = stdenv.mkDerivation {
          name = "website";
          # Only include the zola relevant files to reduce frivolous rebuilds.
          src = builtins.path {
            path = ./.;
            name = "website-src";
            filter = path: type:
              (
                x:
                  builtins.any (file: lib.hasSuffix file x) ["config.toml"]
                  || builtins.any (dir: lib.hasInfix dir x) ["content" "static" "templates"]
              )
              path;
          };
          buildInputs = [zola nodePackages_latest.prettier];
          configurePhase = "mkdir --parents themes && ln --symbolic ${theme} themes/${themeName}";
          buildPhase = ''
            # Build
            zola build
            # Format
            prettier --bracket-same-line true --write public
            # Strip empty lines
            find public -type f -name '*.html' -exec sed -i '/^$/d' {} +
          '';
          installPhase = "cp --recursive public $out";
        };

        # `nix develop`
        devShell = mkShell {
          buildInputs = [zola];
          shellHook = ''
            mkdir --parents themes && ln --symbolic --force --no-dereference ${theme} themes/${themeName}
          '';
        };
      });
}
