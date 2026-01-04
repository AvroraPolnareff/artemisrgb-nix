# Nix Packages for Artemis RGB

```
Artemis is a lighting software for gamers that creates realistic lighting effects by using device location.

It works across multiple brands and is open-source, allowing users to add their own devices, effects, and games.

Artemis is designed to have minimal impact on gaming performance, ensuring a seamless experience.

```
> https://artemis-rgb.com/

## Flake structure
- The "unwrapped" version of Artemis, without any plugins, in `artemisrgb-unwrapped` derivation
- All of the builtin plugins in `artemisrgb-plugins` derivation
- Plugins and the app together in `artemisrgb` derivation

## How to install 
### In nixos
```nix
{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    artemisrgb.url = "github:AvroraPolnareff/artemisrgb-nix";
  };

  outputs = { self, ... }@inputs:
  {
    nixosConfigurations.nixos = {
      modules = [
        {
          environment.systemPackages = [
            inputs.artemisrgb.packages.x86_64-linux.default
          ];
        }
      ];  
    };
  };
}
```
## Caveats
- Some device plugins seem not to be working (`Artemis.Plugins.Devices.Wooting` as an example)
- There is no macos build right now
- It is not possible to customize which plugins should be included in the final package


## Additional Information
### Links to original repos
- https://github.com/Artemis-RGB/Artemis

- https://github.com/Artemis-RGB/Artemis.Plugins
