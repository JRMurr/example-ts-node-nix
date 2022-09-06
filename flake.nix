{
  description = "Sample Nix ts-node build";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    gitignore = {
      url = "github:hercules-ci/gitignore.nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, flake-utils, gitignore, ... }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs { inherit system; };
        nodejs = pkgs.nodejs-16_x;

        appBuild = pkgs.stdenv.mkDerivation {
          name = "example-ts-node";
          version = "0.1.0"; # TODO: parse from package.json
          src = gitignore.lib.gitignoreSource ./.;
          buildInputs = [ nodejs ];
          # https://nixos.org/manual/nixpkgs/stable/#sec-stdenv-phases
          buildPhase = ''
            runHook preBuild
            npm ci # sad does not work, no internet access in pure mode
            npm run build
            runHook postBuild
          '';
          # checkPhase = ''
          #   runHook preCheck
          #   npm run test
          #   runHook postCheck
          # '';
          installPhase = ''
            runHook preInstall

            cp -r node_modules $out/node_modules
            cp package.json $out/package.json
            cp -r dist $out/dist

            runHook postInstall
          '';
        };

      in with pkgs; {
        defaultPackage = appBuild;
        devShell = mkShell { buildInputs = [ nodejs ]; };
      });
}
