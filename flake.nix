{
  description = "Artemis";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";
    flake-parts.url = "github:hercules-ci/flake-parts";
    treefmt-nix.url = "github:numtide/treefmt-nix";
  };

  outputs =
    {
      self,
      nixpkgs,
      flake-parts,
      treefmt-nix,
      ...
    }@inputs:
    flake-parts.lib.mkFlake { inherit inputs; } {
      systems = [
        "x86_64-linux"
        "aarch64-linux"
      ];
      imports = [
        treefmt-nix.flakeModule
      ];
      perSystem =
        { pkgs, ... }:
        let
          lib = pkgs.lib;
          artemisrgb-unwrapped = pkgs.callPackage ./packages/artemisrgb-unwrapped { };
          artemisrgb-plugins = pkgs.callPackage ./packages/artemisrgb-plugins {
            inherit artemisrgb-unwrapped;
          };
          artemisrgb = pkgs.callPackage ./packages/artemisrgb {
            inherit artemisrgb-unwrapped artemisrgb-plugins;
          };
        in
        {
          packages.artemisrgb-unwrapped = artemisrgb-unwrapped;
          packages.artemisrgb-plugins = artemisrgb-plugins;
          packages.artemisrgb = artemisrgb;
          packages.default = artemisrgb;
          devShells.default = pkgs.mkShell {
            buildInputs = with pkgs; [
              pkgs.dotnetCorePackages.sdk_9_0
              pkgs.dotnetCorePackages.runtime_9_0
            ];
          };
          treefmt.programs.nixfmt = {
            enable = true;
            package = pkgs.nixfmt-rfc-style;
          };
        };
    };
}
