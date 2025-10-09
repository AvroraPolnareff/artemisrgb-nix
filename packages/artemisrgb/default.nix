{
  lib,
  runCommand,
  makeWrapper,
  symlinkJoin,
}:
artemisrgb-unwrapped:
let
  inherit (lib) getExe;
  wrapper =
    {
      builtinPlugins ? [ ],
    }:
    let
      builtinPluginsDir = symlinkJoin {
        name = "artemisrgb-plugins";
        paths = builtinPlugins;
      };
    in
    runCommand "artemisrgb-${artemisrgb-unwrapped.version}"
      {
        inherit (artemisrgb-unwrapped) version meta;
        pname = "artemisrgb";
        nativeBuildInputs = [ makeWrapper ];
        passthru = {
          unwrapped = artemisrgb-unwrapped;
          inherit builtinPlugins;
        };
      }
      ''
        mkdir -p "$out/bin"
        ln -s "${artemisrgb-unwrapped}/share" "$out/share"
        makeWrapper "${getExe artemisrgb-unwrapped}" "$out/bin/artemisrgb" \
          --set ARTEMISRGB_BUILTIN_PLUGIN_DIR ${builtinPluginsDir}
      '';
in
lib.makeOverridable wrapper
