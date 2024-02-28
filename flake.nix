{
    description = "Tikan -- Fog of War Chess ";

    # TODO: Can Nix also install the bun packages too? Or would that just be a hook to run `bun i` lol.

    inputs = {
        nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";
        flake-parts.url = "github:hercules-ci/flake-parts";
        devshell.url = "github:numtide/devshell";
        noir.url = "github:noir-lang/noir/5be9f9d7e2f39ca228df10e5a530474af0331704";
    };

    outputs = inputs@{ self, nixpkgs, devshell, flake-parts, noir }:
        flake-parts.lib.mkFlake { inherit inputs; } {
            imports = [
                devshell.flakeModule
                # noir.packages
                # flake-parts.flakeModules.easyOverlay
            ];

            systems = [
                "aarch64-linux"
                "aarch64-darwin"
                "x86_64-linux"
                "x86_64-darwin"
            ];

            perSystem = { pkgs, ... }: rec {
              # Docs: https://flake.parts/overlays#an-overlay-for-free-with-flake-parts
                # overlayAttrs = {
                #     inherit (noir.packages) nargo;
                # };

                # packages.default = pkgs.buildGo121Module {
                #     name = "bingbongbaz";

                #     src = ./.;

                #     vendorHash = "sha256-Wn1q+IPjf9EnCXpgzUHmsg2BbGS9mE0Lbk4kQ145n2s=";

                #     # Build flags.
                #     CGO_ENABLED = 0;
                #     flags = [ "-trimpath" ];
                #     ldflags = [
                #         "-s"
                #         "-w"
                #         "-extldflags -static"
                #     ];
                # };

                packages.nargo = noir.packages.nargo;

                # `nix develop`.
                devshells.default = {
                    # Packages present in the default shell.
                    packages = with pkgs; [
                      bun
                    ] ++ [ noir.packages.${system}.nargo ];

                    # Commands present in the default shell.
                    # commands = [
                        # {
                        #     # TODO: Probably `go install` instead?
                        #     category = "[codebase]";
                        #     name = "build";
                        #     help = "build project for production";
                        #     command = "nix build";
                        # }
                        # {
                        #     category = "[codebase]";
                        #     name = "dev";
                        #     help = "run project for development";
                        #     # TODO: Use same env vars from `nix build`?
                        #     command = "CGO_ENABLED=0 go run main.go $@";
                        # }
                    # ];
                };
            };
        };
}
