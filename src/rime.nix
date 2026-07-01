{
  rime-prelude,
  rime-luna-pinyin,
  rime-essay,
  rime-emoji,
  plum,
  ...
}:
{
  pkgs,
  lib,
  config,
  osConfig,
  stdenv,
  ...
}:
let
  getConfigInputMethod = lib.attrsets.attrByPath [ "i18n" "inputMethod" "type" ] null;
  get-rime-dir = {
    fcitx5 = ".local/share/fcitx5/rime";
    ibus = ".config/ibus/rime";
    fcitx = ".config/fcitx/rime";
  };
  rime-dir = get-rime-dir.${config.rime-config.type};
  rime-file = file: "${rime-dir}/${file}";
  yaml = pkgs.formats.yaml { };

  filter-rime-file = builtins.filter (
    file:
    lib.any (f: f file) [
      (lib.hasSuffix ".yaml")
      (lib.hasSuffix ".txt")
      (file: file == "opencc")
    ]
  );

  source =
    src:
    (lib.pipe src [
      builtins.readDir
      builtins.attrNames
      filter-rime-file
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
      description = "Rime 配置文件的來源目錄列表。";
    };

    type = lib.mkOption {
      type = lib.types.enum [
        "fcitx5"
        "ibus"
        "fcitx"
      ];
      default = lib.findFirst (x: getConfigInputMethod x != null) "fcitx5" [
        config
        osConfig
      ];
      description = "你是使用的什麼方式啟用 rime 的輸入法框架？";
    };

    schemas = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [
        "luna_pinyin"
        "luna_pinyin_fluency"
        "luna_pinyin_simp"
        "luna_pinyin_tw"
      ];
      description = "啟用的 Rime schema 名稱列表，會在 rime 配置目錄下生成對應的 .custom.yaml 文件。";
    };
  };

  config = lib.mkIf config.rime-config.enable {
    home.file = lib.mkMerge (
      (map source config.rime-config.sources)
      ++ [
        (patch config.rime-config.schemas)
        {
          "${rime-dir}/default.custom.yaml".source = yaml.generate "default.custom.yaml" {
            patch = {
              "schema_list/=" = map (x: { schema = x; }) config.rime-config.schemas;
            };
          };
        }
      ]
    );
  };
}
