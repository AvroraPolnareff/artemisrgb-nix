{
  lib,
  buildDotnetModule,
  autoPatchelfHook,
  fetchFromGitHub,
  dotnetCorePackages,
  zip,

  libgcc,
  hidapi,

  artemisrgb-unwrapped,
  ...
}:
let
  inherit (lib) getExe;
in
let
  pluginPaths = [
    "./src/Collections/Artemis.Plugins.Audio"
    "./src/Collections/Artemis.Plugins.Input"
    "./src/Collections/Artemis.Plugins.PhilipsHue"
    "./src/Collections/Artemis.Plugins.WebAPI"
    "./src/Devices/Artemis.Plugins.Devices.Asus"
    "./src/Devices/Artemis.Plugins.Devices.CoolerMaster"
    "./src/Devices/Artemis.Plugins.Devices.Corsair"
    "./src/Devices/Artemis.Plugins.Devices.Debug"
    "./src/Devices/Artemis.Plugins.Devices.DMX"
    "./src/Devices/Artemis.Plugins.Devices.Logitech"
    "./src/Devices/Artemis.Plugins.Devices.Msi"
    "./src/Devices/Artemis.Plugins.Devices.Novation"
    "./src/Devices/Artemis.Plugins.Devices.OpenRGB"
    "./src/Devices/Artemis.Plugins.Devices.PicoPi"
    "./src/Devices/Artemis.Plugins.Devices.Razer"
    "./src/Devices/Artemis.Plugins.Devices.SteelSeries"
    #"./src/Devices/Artemis.Plugins.Devices.Wooting"
    "./src/Devices/Artemis.Plugins.Devices.WS281X"
    "./src/LayerBrushes/Artemis.Plugins.LayerBrushes.Ambilight"
    "./src/LayerBrushes/Artemis.Plugins.LayerBrushes.Color"
    "./src/LayerBrushes/Artemis.Plugins.LayerBrushes.Noise"
    "./src/LayerBrushes/Artemis.Plugins.LayerBrushes.Particle"
    "./src/LayerBrushes/Artemis.Plugins.LayerBrushes.RemoteControl"
    "./src/LayerEffects/Artemis.Plugins.LayerEffects.Filter"
    "./src/LayerEffects/Artemis.Plugins.LayerEffects.LedReveal"
    "./src/LayerEffects/Artemis.Plugins.LayerEffect.Strobe"
    "./src/Modules/Artemis.Plugins.Modules.DefaultProfile"
    "./src/Modules/Artemis.Plugins.Modules.Performance"
    "./src/Modules/Artemis.Plugins.Modules.Processes"
    "./src/Modules/Artemis.Plugins.Modules.Profiles"
    "./src/Modules/Artemis.Plugins.Modules.TestData"
    "./src/Modules/Artemis.Plugins.Modules.Time"
    "./src/Nodes/Artemis.Plugins.Nodes.General"
    "./src/Other/Artemis.Plugins.Profiling"
  ];
  dotnet-sdk = dotnetCorePackages.sdk_9_0;
in
buildDotnetModule {
  inherit dotnet-sdk;
  inherit pluginPaths;
  pname = "artemisrgb-plugins";
  version = "2.0.0";
  src = fetchFromGitHub {
    owner = "Artemis-RGB";
    repo = "Artemis.Plugins";
    rev = "5d2fe3d028c24b5cc78fc748b431ed1b984b3cd4";
    hash = "sha256-IX5ZiElbg/wKpMQ1mDEl7Dktp7PqCfrksIgXp057LVk=";
  };
  projectFile = "./src/Artemis.Plugins.sln";
  nugetDeps = ./deps.json;
  dotnetRestoreFlags = [ "--artifacts-path ./artifacts" ];
  dotnetBuildFlags = [ "--artifacts-path ./artifacts" ];
  patchPhase = ''
    # for ease of use Artemis.Plugins has a references to local copy of artemis repo
    # but in order to build these plugins in nix we want to use paths to our unwrapped package in nix store
    substituteInPlace ./src/Directory.Build.props \
      --replace-fail '..\..\..\..\Artemis\src\Artemis.Core\bin\net9.0\Artemis.Core.dll' \
      '${artemisrgb-unwrapped}/lib/artemisrgb-unwrapped/Artemis.Core.dll'            
    substituteInPlace ./src/Directory.Build.props \
      --replace-fail '..\..\..\..\Artemis\src\Artemis.Core\bin\net9.0\Artemis.Storage.dll' \
      '${artemisrgb-unwrapped}/lib/artemisrgb-unwrapped/Artemis.Storage.dll'            
    substituteInPlace ./src/Directory.Build.props \
      --replace-fail '..\..\..\..\Artemis\src\Artemis.UI.Shared\bin\net9.0\Artemis.UI.Shared.dll' \
      '${artemisrgb-unwrapped}/lib/artemisrgb-unwrapped/Artemis.UI.Shared.dll' 
  '';
  dontDotnetInstall = true;
  buildInputs = [
    libgcc
    hidapi
  ];
  nativeBuildInputs = [
    autoPatchelfHook
  ];
  installPhase = ''
    runHook preInstall
    mkdir -p $out
    for pluginPath in $pluginPaths; do
      pluginName="$(basename "$pluginPath")"
      cd "./artifacts/bin/$pluginName/release"
      ${getExe zip} -r "$out/$pluginName.zip" ./*
      cd -
    done
    runHook postInstall
  '';
  meta = {
    description = "Artemis.Plugins";
    platforms = lib.platforms.linux;
  };
}
