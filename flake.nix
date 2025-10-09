{
  description = "Artemis";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";
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
        lib = nixpkgs.lib;
        pkgs = nixpkgs.legacyPackages.${system};
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
        formatter = pkgs.nixfmt-rfc-style;
        devShells.default = pkgs.mkShell {
          buildInputs = with pkgs; [
            pkgs.dotnetCorePackages.sdk_9_0
            pkgs.dotnetCorePackages.runtime_9_0
          ];
        };
      }
    );
}
