{
  description = "Nix rime configuration flake";

  inputs = {
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
    {
      rime-prelude,
      rime-luna-pinyin,
      rime-essay,
      rime-emoji,
      plum,
      ...
    }:
    {
      homeModules.default = import ./src/rime.nix {
        inherit
          rime-prelude
          rime-luna-pinyin
          rime-essay
          rime-emoji
          plum
          ;
      };

      rimeModules.default = [
        rime-prelude
        rime-luna-pinyin
        rime-essay
        rime-emoji
      ];

      patchUtils = import ./utils.nix;
    };
}
