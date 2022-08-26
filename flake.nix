# Nix flake, see: <https://nixos.org/manual/nix/unstable/command-ref/new-cli/nix3-flake.html>
{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-22.05"; # Nix package repository
    utils.url = "github:numtide/flake-utils"; # Flake utility functions
  };

  outputs = { self, nixpkgs, utils }:
    utils.lib.eachDefaultSystem (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
        theme = pkgs.stdenv.mkDerivation {
          name = "zola-theme-terminimal";
          src = builtins.fetchGit {
            url = "https://github.com/pawroman/zola-theme-terminimal.git";
            rev = "0cc423545a63a9bd6ea6fc66068d03625d574876";
            ref = "master";
          };
          patchPhase = "substituteInPlace sass/color/pink.scss --replace '238,114,241' '171,158,239'";
          installPhase = "cp -R . $out";
        };
        themeName = pkgs.lib.toLower ((builtins.fromTOML (builtins.readFile "${theme}/theme.toml")).name);
      in
      {
        # `nix build`
        defaultPackage = pkgs.stdenv.mkDerivation {
          name = "website";
          src = with pkgs; builtins.path {
            path = ./.;
            name = "website-src";
            filter = path: type: (x:
              builtins.any (file: lib.hasSuffix file x) [ "config.toml" ] ||
              builtins.any (dir: lib.hasInfix dir x) [ "content" "static" "templates" ]
            ) path;
          };
          buildInputs = with pkgs; [ zola ];
          configurePhase = "mkdir --parents themes && ln --symbolic ${theme} themes/${themeName}";
          buildPhase = "zola build";
          installPhase = "cp --recursive public $out";
        };

        # `nix develop`
        devShell = pkgs.mkShell ({
          buildInputs = [ pkgs.zola ];
          shellHook = ''
            mkdir --parents themes && ln --symbolic --force --no-dereference ${theme} themes/${themeName}
          '';
        });
      });
}
