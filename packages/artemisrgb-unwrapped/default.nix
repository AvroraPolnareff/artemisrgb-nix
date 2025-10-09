{
  lib,
  buildDotnetModule,
  fetchFromGitHub,
  copyDesktopItems,
  makeDesktopItem,
  dotnetCorePackages,
  ...
}:
let
  dotnet-sdk = dotnetCorePackages.sdk_9_0;
in
buildDotnetModule (finalAttrs: {
  inherit dotnet-sdk;
  pname = "artemisrgb-unwrapped";
  version = "2.0.0";
  src = fetchFromGitHub {
    owner = "Artemis-RGB";
    repo = "Artemis";
    rev = "acd35176e1c6661a887e467ef4b294eddb532726";
    hash = "sha256-ufYe3Nxcqy0SeXyfpgsUlvSFUj6G/l/0eOSuuu3eJ5E=";
  };
  projectFile = "./src/Artemis.UI.Linux/Artemis.UI.Linux.csproj";
  nugetDeps = ./deps.json;
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
    copyDesktopItems
  ];
  desktopItems = [
    (makeDesktopItem {
      name = "artemisrgb";
      desktopName = "Artemis RGB";
      icon = "artemis";
      exec = "artemisrgb";
      categories = [ "Utility" ];
      keywords = [
        "artemis"
        "rgb"
        "lighting"
        "software"
      ];
    })
  ];
  meta = {
    description = "Artemis";
    mainProgram = "artemisrgb";
    platforms = lib.platforms.linux;
  };
})
