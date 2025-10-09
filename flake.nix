{
  description = "Artemis";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils}:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
        lib = nixpkgs.lib;
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
        dotnet-sdk = pkgs.dotnetCorePackages.sdk_9_0;
        dotnet-runtime = pkgs.dotnetCorePackages.runtime_9_0;
        artemisrgb-unwrapped = pkgs.buildDotnetModule (finalAttrs: {
          inherit dotnet-sdk dotnet-runtime;
          pname = "artemisrgb-unwrapped";
          version = "2.0.0";
          src = pkgs.fetchFromGitHub {
            owner = "Artemis-RGB";
            repo = "Artemis";
            rev = "acd35176e1c6661a887e467ef4b294eddb532726";
            hash = "sha256-ufYe3Nxcqy0SeXyfpgsUlvSFUj6G/l/0eOSuuu3eJ5E=";
          };
          projectFile = "./src/Artemis.UI.Linux/Artemis.UI.Linux.csproj";
          nugetDeps = ./artemis.deps.json;
          executables = [ "Artemis.UI.Linux" ];
          patchPhase = ''
            # for some reason original constant doesn't changes at runtime so we replace it to an env variable
            substituteInPlace ./src/Artemis.Core/Services/PluginManagementService.cs \
              --replace-fail 'DirectoryInfo builtInPluginDirectory = new(Path.Combine(Constants.ApplicationFolder, "Plugins"));' \
              'DirectoryInfo builtInPluginDirectory = new(Environment.GetEnvironmentVariable("ARTEMISRGB_BUILTIN_PLUGIN_DIR") ?? Path.Combine(Constants.ApplicationFolder, "Plugins"));'
          '';
          postInstall = ''
            mkdir -p "$out/share/icons"
            ln -s "$out/lib/${finalAttrs.pname}/Icons" "$out/share/icons/hicolor"
          '';
          postFixup = ''
            mv $out/bin/Artemis.UI.Linux $out/bin/artemisrgb
          '';
          nativeBuildInputs = [
            pkgs.copyDesktopItems
          ];
          desktopItems = [
            (pkgs.makeDesktopItem {
              name = "artemisrgb";
              desktopName = "Artemis RGB";
              icon = "artemis";
              exec = "artemisrgb"; 
              categories = [ "Utility" ];
              keywords = [ "artemis" "rgb" "lighting" "software" ];
            })
          ];
          meta = with pkgs.lib; {
            description = "Artemis";
            mainProgram = "artemisrgb";
            platforms = platforms.linux;
          };
        });
        artemisrgb-plugins = pkgs.buildDotnetModule {
          inherit dotnet-sdk dotnet-runtime;
          inherit pluginPaths; 
          pname = "artemisrgb-plugins";
          version = "2.0.0";
          src = pkgs.fetchFromGitHub {
            owner = "Artemis-RGB";
            repo = "Artemis.Plugins";
            rev = "5d2fe3d028c24b5cc78fc748b431ed1b984b3cd4";
            hash = "sha256-IX5ZiElbg/wKpMQ1mDEl7Dktp7PqCfrksIgXp057LVk=";
          };
          projectFile = "./src/Artemis.Plugins.sln";
          nugetDeps = ./artemis.plugins.deps.json;
          dotnetRestoreFlags = ["--artifacts-path ./artifacts"];
          dotnetBuildFlags = ["--artifacts-path ./artifacts"];
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
        artemisrgb = pkgs.runCommand "artemisrgb-${artemisrgb-unwrapped.version}" {
          nativeBuildInputs = [ pkgs.makeWrapper ];
        }
        ''
          mkdir -p "$out/bin"
          ln -s "${artemisrgb-unwrapped}/share" "$out/share"
          makeWrapper "${lib.getExe artemisrgb-unwrapped}" "$out/bin/artemisrgb" \
            --set ARTEMISRGB_BUILTIN_PLUGIN_DIR ${artemisrgb-plugins}
        '';
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
      });
}