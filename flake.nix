{
  inputs = {
    flake-utils.url = "github:numtide/flake-utils";
    devshell.url = "github:numtide/devshell";
  };


  outputs = { self, nixpkgs, flake-utils, devshell }:
    flake-utils.lib.eachSystem [ "x86_64-linux" "aarch64-linux" ] (system:
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
            super-slicer
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
                "$PRJ_ROOT/fix-gcode.awk" "$@"
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
          ];
        };
      }
    );
}
