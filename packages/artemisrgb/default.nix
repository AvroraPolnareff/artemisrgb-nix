{
  lib,
  runCommand,
  makeWrapper,

  artemisrgb-unwrapped,
  artemisrgb-plugins,
}:
let
  inherit (lib) getExe;
in
runCommand "artemisrgb-${artemisrgb-unwrapped.version}"
  {
    inherit (artemisrgb-unwrapped) version meta;
    pname = "artemisrgb";
    nativeBuildInputs = [ makeWrapper ];
  }
  ''
    mkdir -p "$out/bin"
    ln -s "${artemisrgb-unwrapped}/share" "$out/share"
    makeWrapper "${getExe artemisrgb-unwrapped}" "$out/bin/artemisrgb" \
      --set ARTEMISRGB_BUILTIN_PLUGIN_DIR ${artemisrgb-plugins}
  ''
