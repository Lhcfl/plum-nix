{ rime-prelude,
  rime-luna-pinyin,
  rime-essay,
  rime-emoji,
}: {
  pkgs,
  lib,
  config,
  osConfig,
  ...
}:
let
  getConfigInputMethod = lib.attrsets.attrByPath ["i18n" "inputMethod" "type"] null;
  get-rime-dir = {
    fcitx5 = ".local/share/fcitx5/rime";
    ibus = ".config/ibus/rime";
    fcitx = ".config/fcitx/rime";
  };
  rime-dir = get-rime-dir.${config.rime-config.type};
  rime-file = file: "${rime-dir}/${file}";
  yaml = pkgs.formats.yaml { };

  source =
    src:
    (lib.pipe src [
      builtins.readDir
      builtins.attrNames
      (builtins.filter (
        name: (lib.hasSuffix ".yaml" name) || (lib.hasSuffix ".txt" name) || name == "opencc"
      ))
      (map (name: {
        name = rime-file name;
        value.source = "${src}/${name}";
      }))
      builtins.listToAttrs
    ]);

  patch =
    schema:
    (lib.pipe schema [
      (map (schema: {
        name = rime-file "${schema}.custom.yaml";
        value.source = yaml.generate "${schema}.custom.yaml" {
          patch.__include = "emoji_suggestion:/patch";
        };
      }))
      builtins.listToAttrs
    ]);

in
{
  options.rime-config = {
    enable = lib.mkEnableOption "Enable rime configuration"; 

    sources = lib.mkOption {
      type = lib.types.listOf lib.types.path;
      default = [
        rime-prelude
        rime-luna-pinyin
        rime-essay
        rime-emoji
      ];
      description = "The sources of the rime configuration.";
    };

    type = lib.mkOption {
      type = lib.types.enum [ "fcitx5" "ibus" "fcitx" ];
      default = lib.findFirst (x : getConfigInputMethod x != null) "fcitx5" [config osConfig];
      description = "the kind of where to put the rime configuration.";
    };

    schemas = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [
        "luna_pinyin"
        "luna_pinyin_fluency"
        "luna_pinyin_simp"
        "luna_pinyin_tw"
      ];
      description = "The schemas of the rime configuration.";
    };
  };

  config = lib.mkIf config.rime-config.enable {
    home.file = lib.mkMerge ([
      (patch config.rime-config.schemas)
    ] ++ (map source config.rime-config.sources));
  };
}
