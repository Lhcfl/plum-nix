{
  description = "Nix rime configuration flake";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";

    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";

    rime-luna-pinyin.url = "github:rime/rime-luna-pinyin";
    rime-luna-pinyin.flake = false;

    rime-essay.url = "github:rime/rime-essay";
    rime-essay.flake = false;

    rime-emoji.url = "github:rime/rime-emoji";
    rime-emoji.flake = false;

    rime-prelude.url = "github:rime/rime-prelude";
    rime-prelude.flake = false;

    plum.url = "github:rime/plum";
    plum.flake = false;
  };

  outputs =
    inputs@{
      self,
      nixpkgs,
      home-manager,
      ...
    }:
    {
      homeModules.default = _: {
        imports = [
          (import ./src/rime.nix {
            inherit (inputs)
              rime-prelude
              rime-luna-pinyin
              rime-essay
              rime-emoji
              plum
              ;
          })
        ];
      };

      homeConfigurations.test = home-manager.lib.homeManagerConfiguration {
        pkgs = import nixpkgs { system = "x86_64-linux"; };

        modules = [
          self.homeModules.default
          {
            home.username = "test";
            home.homeDirectory = "/tmp/test-home";
            home.stateVersion = "26.05";

            plum-nix.enable = true;
          }
        ];
      };
    };
}
