{
  inputs = {
    flake-utils.url = "github:numtide/flake-utils";
    devshell.url = "github:numtide/devshell";
  };


  outputs = { self, nixpkgs, flake-utils, devshell }:
    flake-utils.lib.eachSystem [ "x86_64-linux" "aarch64-linux" ]
      (system:
        let
          pkgs = import nixpkgs {
            inherit system;
            overlays = [ devshell.overlay ];
          };
        in
        {
          checks = {
            awk-lint = pkgs.runCommand "awk-lint"
              { buildInputs = [ pkgs.gawk ]; } ''
              gawk --lint -f ${./fix-gcode.awk} /dev/null
              gawk --lint=fatal -f ${./fix-gcode.awk} /dev/null
              touch $out
            '';
            nixpkgs-fmt = pkgs.runCommand "nixpkgs-fmt"
              { buildInputs = [ pkgs.nixpkgs-fmt ]; } ''
              nixpkgs-fmt --check ${./.}
              touch $out
            '';
            prettier = pkgs.runCommand "prettier"
              { buildInputs = [ pkgs.nodePackages.prettier ]; } ''
              prettier --check ${./.}
              touch $out
            '';
            shellcheck = pkgs.runCommand "shellcheck"
              { buildInputs = [ pkgs.shellcheck ]; } ''
              shellcheck ${./post-process.sh}
              touch $out
            '';
          };

          devShells.default = pkgs.devshell.mkShell {
            imports = [ "${devshell}/extra/git/hooks.nix" ];
            name = "dev-shell";
            packages = with pkgs; [
              gawk
              glow
              nixpkgs-fmt
              nodePackages.prettier
              shellcheck
            ];
            git.hooks = {
              enable = true;
              pre-commit.text = ''
                nix flake check
              '';
            };
            commands = [
              {
                name = "help";
                command = ''glow "$PRJ_ROOT/README.md"'';
                help = "show the readme";
              }
              {
                name = "fix-gcode";
                command = ''
                  exec "$PRJ_ROOT/fix-gcode.awk" "$@"
                '';
                help = "fix gcode, writing to stdout";
              }
              {
                name = "pull-superslicer-config";
                command = ''
                  cp --recursive -- "$HOME/.config/SuperSlicer/"{filament,print,printer} "$PRJ_ROOT/superslicer-config"
                '';
                help = "copies the current SuperSlicer config from XDG_CONFIG_HOME into this repo";
              }
              {
                name = "superslicer";
                command = ''
                  exec ${pkgs.super-slicer}/bin/superslicer --datadir "$PRJ_ROOT/superslicer-config" "$@"
                '';
                help = "launch the SuperSlicer with the configuration from this repo";
              }
            ];
          };
        }
      )

    // {
      packages =
        let
          system = "x86_64-linux";
          pkgs = import nixpkgs {
            inherit system;
            config.allowUnfree = true;
          };
        in
        {
          ${system}.upstudio = pkgs.stdenv.mkDerivation rec {
            pname = "upstudio";
            version = "3.2-6";
            src = pkgs.requireFile {
              name = "${pname}_${version}_amd64.deb";
              url = "http://tiertime.com";
              sha256 = "0bq7709kvx99a6fjhm2cfav41v01h48b6ycs56dv1d4rcc9ga4rm";
            };
            dontUnpack = true;
            nativeBuildInputs = with pkgs; [ autoPatchelfHook qt5.wrapQtAppsHook dpkg ];
            buildInputs = with pkgs; [
              libusb
              qt5.qtbase
              qt5.qtgraphicaleffects
              qt5.qtquickcontrols2
              qt5.qtserialport
            ];
            installPhase = ''
              dpkg-deb --extract $src $out
              mkdir $out/bin
              for file in UPStudio3 Wand ; do
                wrapQtApp $out/opt/tiertime/upstudio/$file
                makeWrapper $out/opt/tiertime/upstudio/$file $out/bin/$file
              done
              chmod g-w $out
            '';
            meta = with pkgs.lib; {
              description = "A slicer for Tiertime & Cetus 3D printers";
              homepage = "https://www.tiertime.com/software/";
              license = licenses.unfree;
              maintainers = [ maintainers.wucke13 ];
              platforms = platforms.linux;
            };
          };
        };
    };
}
