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
          format = pkgs.runCommand "check-awk-posix"
            { buildInputs = [ pkgs.gawk ]; } ''
            gawk --lint -f ${./fix-gcode.awk} /dev/null
            gawk --lint=fatal -f ${./fix-gcode.awk} /dev/null
            touch $out
          '';
        };

        devShells.default = pkgs.devshell.mkShell {
          imports = [ "${devshell}/extra/git/hooks.nix" ];
          name = "dev-shell";
          packages = with pkgs; [ gawk glow super-slicer ];
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
                [ $# != 1 ] && {
                  echo "usage: fix-gcode FILENAME"
                  echo "will create a file with the suffix _fixed"
                  exit
                }
                
                "$PRJ_ROOT/fix-gcode.awk" "$1" > "''${1%%.tsg}_fixed.tsg"
              '';
              help = "fix gcode, writing to a new file";
            }
          ];
        };
      }
    );
}
