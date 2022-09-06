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
        node2nixOutput = import ./nix { inherit pkgs nodejs system; };
        # TODO: the source dir of this seems to be re-built alot
        # try https://github.com/svanderburg/node2nix/issues/301 
        nodeDeps = node2nixOutput.nodeDependencies;
        app = pkgs.stdenv.mkDerivation {
          name = "example-ts-node";
          version = "0.1.0";
          # TODO: https://github.com/hercules-ci/gitignore.nix/blob/master/docs/gitignoreFilter.md to filter nix files
          src = gitignore.lib.gitignoreSource ./.;
          buildInputs = [ nodejs ];
          buildPhase = ''
            runHook preBuild

            ln -sf ${nodeDeps}/lib/node_modules ./node_modules
            export PATH="${nodeDeps}/bin:$PATH"

            # Build the distribution bundle in "dist"
            npm run build

            runHook postBuild
          '';
          installPhase = ''
            runHook preInstall

            mkdir -p $out/bin
            cp package.json $out/package.json
            cp -r dist $out/dist
            ln -sf ${nodeDeps}/lib/node_modules $out/node_modules

            # copy entry point, in this case our index.ts has the node shebang
            # nix will patch the shebang to be the node version specified in buildInputs
            cp dist/index.js $out/bin/example-ts-nix
            chmod a+x $out/bin/example-ts-nix

            runHook postInstall
          '';
        };

      in with pkgs; {
        packages = {
          app = app;
          docker = dockerTools.buildImage {
            name = app.name;
            copyToRoot = pkgs.buildEnv {
              name = app.name;
              paths = [ app ];
              pathsToLink = [ "/bin" "/dist" "/node_modules" "package.json" ];
            };

            # contents = [ app ];
            # This ensures symlinks to directories are preserved in the image
            keepContentsDirlinks = true;
            # This adds a correct timestamp, however breaks binary reproducibility
            # created = "now";
            # extraCommands = ''
            #   mkdir -m 1777 tmp
            # '';
            config = { Cmd = [ "/bin/example-ts-nix" ]; };
          };
        };
        defaultPackage = app;
        devShell = mkShell { buildInputs = [ nodejs node2nix ]; };
      });
}
