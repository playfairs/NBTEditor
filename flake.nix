{
  description = "NBTEditor - An Embedded fork of webNBT";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs =
    {
      self,
      nixpkgs,
      flake-utils,
    }:
    flake-utils.lib.eachDefaultSystem (
      system:
      let
        pkgs = nixpkgs.legacyPackages.${system};

        emscripten = pkgs.emscripten;

        nativeBuildInputs = with pkgs; [
          emscripten
          gnumake
          python3
        ];

        runtimeInputs = with pkgs; [
          python3
        ];
      in
      {
        devShells.default = pkgs.mkShell {
          buildInputs = nativeBuildInputs ++ runtimeInputs;

          shellHook = ''
            serve-nbteditor() {
              echo "Starting NBTEditor server at http://localhost:8080"
              cd web-app && python3 -m http.server 8080
            }
          '';
        };

        packages.default = pkgs.stdenv.mkDerivation {
          pname = "nbteditor";
          version = "1.0.0";

          src = ./.;

          nativeBuildInputs = nativeBuildInputs;

          buildPhase = ''
            source ${emscripten}/emsdk_env.sh
            make build
          '';

          installPhase = ''
            mkdir -p $out
            cp -r web-app/* $out/
          '';
        };

        apps.default = {
          type = "app";
          program = toString (
            pkgs.writeShellScript "serve-nbteditor" ''
              cd web-app
              echo "Starting NBTEditor server at http://localhost:8080"
              ${pkgs.python3}/bin/python3 -m http.server 8080
            ''
          );
        };

        formatter = pkgs.nixfmt;

        packages.desktop = pkgs.stdenv.mkDerivation {
          pname = "nbteditor-desktop";
          version = "1.0.0";

          src = ./.;

          nativeBuildInputs = with pkgs; [
            nodejs
            npm
            pkgs.electron
            pkgs.electron-builder
          ];

          buildPhase = ''
            npm ci
            npm run build
          '';

          installPhase = ''
            mkdir -p $out/bin
            mkdir -p $out/share/nbteditor
            cp -r dist/* $out/share/nbteditor/
            cat > $out/bin/nbteditor << 'EOF'
            #!/bin/sh
            exec ${pkgs.electron}/bin/electron $out/share/nbteditor/nbteditor
            EOF
            chmod +x $out/bin/nbteditor
          '';
        };
      }
    );
}
