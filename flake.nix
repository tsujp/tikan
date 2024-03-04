{
    description = "Tikan -- Fog of War Chess";

    inputs = {
        nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";
        flake-parts.url = "github:hercules-ci/flake-parts";
        devshell.url = "github:numtide/devshell";
        noir.url = "github:noir-lang/noir/cb4c1c5264b95d01f69d99f916ced71ad9cdc9d1";
        # noir.url = "github:tsujp/noir/0cf043d81e2da7c4b23c4b18e0c3a944dd7ea017";
        # noir.url = "github:tsujp/noir/5be9f9d7e2f39ca228df10e5a530474af0331704";
    };

    outputs = inputs@{ self, nixpkgs, flake-parts, ... }:
        flake-parts.lib.mkFlake { inherit inputs; } {
            imports = [
                inputs.devshell.flakeModule
            ];

            systems = [
                "aarch64-linux"
                "aarch64-darwin"
                "x86_64-linux"
                "x86_64-darwin"
            ];

            perSystem = { pkgs, ... }: rec {
                packages.noir = inputs.noir.packages;

                devshells.default = {
                    packages = with pkgs; [
                        bun
                    ] ++ [ packages.noir.${system}.nargo ];
                };
            };
        };
}
