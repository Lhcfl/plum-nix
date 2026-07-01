{
  description = "Nix rime configuration flake";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";

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

  outputs = inputs:
    {
      homeModules.default = import ./src/rime.nix {
        inherit (inputs)
          rime-prelude
          rime-luna-pinyin
          rime-essay
          rime-emoji
          plum
          ;
      };
    };
}
