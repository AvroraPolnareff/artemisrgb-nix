{
  description = "Artemis";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils}:
    flake-utils.lib.eachDefaultSystem (system:
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
        pkgs = nixpkgs.legacyPackages.${system};
        lib = nixpkgs.lib;
        artemisSrc = pkgs.fetchFromGitHub {
          owner = "Artemis-RGB";
          repo = "Artemis";
          rev = "acd35176e1c6661a887e467ef4b294eddb532726";
          hash = "sha256-ufYe3Nxcqy0SeXyfpgsUlvSFUj6G/l/0eOSuuu3eJ5E=";
        };
        artemisPluginsSrc = pkgs.fetchFromGitHub {
          owner = "Artemis-RGB";
          repo = "Artemis.Plugins";
          rev = "5d2fe3d028c24b5cc78fc748b431ed1b984b3cd4";
          hash = "sha256-IX5ZiElbg/wKpMQ1mDEl7Dktp7PqCfrksIgXp057LVk=";
        };
        dotnet-sdk = pkgs.dotnetCorePackages.sdk_9_0;
        dotnet-runtime = pkgs.dotnetCorePackages.runtime_9_0;
        artemisrgb-unwrapped = pkgs.buildDotnetModule {
          inherit dotnet-sdk dotnet-runtime;
          pname = "artemisrgb-unwrapped";
          version = "2.0.0";
          src = artemisSrc;
          projectFile = "./src/Artemis.UI.Linux/Artemis.UI.Linux.csproj";
          nugetDeps = ./artemis.deps.json;
          executables = [ "Artemis.UI.Linux" ];
          patchPhase = ''
            substituteInPlace ./src/Artemis.Core/Services/PluginManagementService.cs \
              --replace-fail 'DirectoryInfo builtInPluginDirectory = new(Path.Combine(Constants.ApplicationFolder, "Plugins"));' \
              'DirectoryInfo builtInPluginDirectory = new(Environment.GetEnvironmentVariable("ARTEMISRGB_BUILTIN_PLUGIN_DIR") ?? Path.Combine(Constants.ApplicationFolder, "Plugins"));'
          '';
          postFixup = ''
            mv $out/bin/Artemis.UI.Linux $out/bin/artemisrgb
          '';
          meta = with pkgs.lib; {
            description = "Artemis";
            mainProgram = "artemisrgb";
            platforms = platforms.linux;
          };
        };
        artemisrgb-plugins = pkgs.buildDotnetModule {
          inherit dotnet-sdk dotnet-runtime;
          inherit pluginPaths; 
          pname = "artemisrgb-plugins";
          version = "2.0.0";
          src = artemisPluginsSrc;
          projectFile = "./src/Artemis.Plugins.sln";
          nugetDeps = ./artemis.plugins.deps.json;
          dotnetRestoreFlags = ["--artifacts-path ./artifacts"];
          dotnetBuildFlags = ["--artifacts-path ./artifacts"];
          patchPhase = ''
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
            pkgs.libgcc
            pkgs.hidapi
          ];
          nativeBuildInputs = [
            pkgs.autoPatchelfHook
          ];
          installPhase = ''
            runHook preInstall
            
            mkdir -p $out
            for pluginPath in $pluginPaths; do
              pluginName="$(basename "$pluginPath")"
              cd "./artifacts/bin/$pluginName/release"
              ${lib.getExe pkgs.zip} -r "$out/$pluginName.zip" ./*
              cd -
            done
            runHook postInstall
          '';
          meta = with pkgs.lib; {
            description = "Artemis.Plugins";
            platforms = platforms.linux;
          };
        };
        artemisrgb = pkgs.writeShellApplication {
          name = "artemisrgb-${artemisrgb-unwrapped.version}";
          text = ''
            export ARTEMISRGB_BUILTIN_PLUGIN_DIR=${artemisrgb-plugins}
            exec ${lib.getExe artemisrgb-unwrapped}
          '';
        };
      in
      {
        packages.artemisrgb-unwrapped = artemisrgb-unwrapped;
        packages.artemisrgb-plugins = artemisrgb-plugins;
        packages.artemisrgb = artemisrgb;
        devShells.default = pkgs.mkShell {
          buildInputs = with pkgs; [
            pkgs.dotnetCorePackages.sdk_9_0
            pkgs.dotnetCorePackages.runtime_9_0
          ];
        };
      });
}