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
  osConfig ? null,
  ...
}:
let
  yaml = pkgs.formats.yaml { };

  get-rime-dir = {
    fcitx5 = ".local/share/fcitx5/rime";
    ibus = ".config/ibus/rime";
    fcitx = ".config/fcitx/rime";
  };

  availableTypes = lib.attrsets.attrNames get-rime-dir;

  rime-dir = get-rime-dir.${config.plum-nix.type};

  # Convert sources attrset to plum targets and copy entries
  copySources = lib.concatStringsSep "\n" (
    lib.lists.imap0 (
      idx: src:
      let
        name = "sources/${toString idx}";
      in
      ''
        mkdir -p package/${name}
        cp -r ${src}/* package/${name}/
        export sources="$sources ${name}"
      ''
    ) config.plum-nix.sources
  );

  copyRecipes = lib.concatStringsSep "\n" (
    lib.lists.imap0 (
      idx:
      { src, recipe }:
      let
        name = "recipes/${toString idx}";
        recipeStr = lib.concatStringsSep " " (map (x: "${name}:${x}") recipe);
      in
      ''
        mkdir -p package/${name}
        cp -r ${src}/* package/${name}/
        export sources="$sources ${name} ${recipeStr}"
      ''
    ) config.plum-nix.recipes
  );

  config-package = pkgs.stdenv.mkDerivation {
    name = "plum-nix-package";
    src = plum;

    buildPhase = ''
      runHook preBuild
      chmod -R u+w .
      patchShebangs .
      mkdir -p $out

      ${copySources}
      ${copyRecipes}
      ${copyCustomize}

      export plum_dir=$(pwd)
      export rime_dir=$out
      export no_update=1

      ./rime-install $sources

      runHook postBuild
    '';

    installPhase = ''
      runHook preInstall
      runHook postInstall
    '';
  };

  copyCustomize = lib.pipe config.plum-nix.customize [
    (lib.attrsets.mapAttrsToList (
      name: value:
      let
        file = yaml.generate "${name}.custom.yaml" { patch = value; };
      in
      ''
        cat ${file} > $out/${name}.custom.yaml
      ''
    ))
    (lib.concatStringsSep "\n")
  ];
in
{
  options.plum-nix = {
    enable = lib.mkEnableOption "Enable rime configuration";

    sources = lib.mkOption {
      type = lib.types.listOf lib.types.path;
      default = [
        rime-prelude
        rime-luna-pinyin
        rime-essay
      ];
      defaultText = lib.literalExpression ''
        [
          rime-prelude
          rime-luna-pinyin
          rime-essay
        ]
      '';
      example = [
        rime-prelude
        rime-luna-pinyin
        rime-essay
        rime-emoji
      ];
      description = ''
        Plum 配置源列表，每项是 rime-* 仓库的本地路径（通常来自本 flake 的 input）。

        这些源的内容会被复制进 plum 的 package 目录，再交给 `rime-install` 处理，等价于 plum 的包安装步骤。默认包含 rime-prelude、rime-luna-pinyin 与 rime-essay。

        参考：<https://github.com/rime/plum>
      '';
    };

    recipes = lib.mkOption {
      type = lib.types.listOf (
        lib.types.submodule {
          options = {
            src = lib.mkOption {
              type = lib.types.path;
              example = rime-emoji;
              description = ''
                recipe 的源
              '';
            };
            recipe = lib.mkOption {
              type = lib.types.listOf lib.types.str;
              example = [ "customize:schema=luna_pinyin" ];
              description = ''
                传给 Plum 的 recipe 列表，每项格式为 `<类别>:<名称>`，例如 `customize:schema=luna_pinyin`。

                参考：<https://github.com/rime/home/wiki/Recipes>
              '';
            };
          };
        }
      );

      default = [
        {
          src = rime-emoji;
          recipe = map (schema: "customize:schema=${schema}") config.plum-nix.schemas;
        }
      ];

      defaultText = lib.literalMD ''
        默认启用 rime-emoji 的 recipe，recipe 会根据 config.plum-nix.schemas 生成，内容如下：

        ```nix
        {
          src = rime-emoji;
          recipe = map (schema: "customize:schema=$${schema}") config.plum-nix.schemas;
        }
        ```
      '';

      example = [
        {
          src = rime-emoji;
          recipe = [ "customize:schema=luna_pinyin" ];
        }
      ];

      description = ''
        Plum recipe 列表，用于在包安装后对配置做额外加工，例如为某个 schema 注入 emoji 词库。

        每项包含 `src`（recipe 所在路径）与 `recipe`（要执行的 recipe 名称列表）。默认会依据 `plum-nix.schemas`，为每个 schema 生成一条 rime-emoji 的 customize recipe。

        参考：<https://github.com/rime/home/wiki/Recipes>
      '';
    };

    type = lib.mkOption {
      type = lib.types.enum availableTypes;

      example = "fcitx5";

      description = ''
        使用的输入法框架，决定 Rime 配置写入哪个目录。可选值：

        - `fcitx5` → `~/.local/share/fcitx5/rime`
        - `ibus` → `~/.config/ibus/rime`
        - `fcitx` → `~/.config/fcitx/rime`

        未显式设置时，会依次回退到 `config.i18n.inputMethod.type` 与 `osConfig.i18n.inputMethod.type`。
      '';

      defaultText = lib.literalMD ''
        依次以下列顺序 fallback:
        - `config.i18n.inputMethod.type`
        - `osConfig.i18n.inputMethod.type`
      '';

      default =
        let
          osType = osConfig.i18n.inputMethod.type or null;
          homeType = config.i18n.inputMethod.type or null;
        in
        if homeType != null then
          homeType
        else if osType != null then
          osType
        else
          "please specify `plum-nix.type`";
    };

    schemas = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [
        "luna_pinyin"
        "luna_pinyin_fluency"
        "luna_pinyin_simp"
        "luna_pinyin_tw"
      ];
      example = [
        "luna_pinyin"
        "luna_pinyin_simp"
      ];
      description = ''
        启用的 Rime 输入法方案（schema）名称列表。

        该列表会写入 default.custom.yaml 的 schema_list，决定切换输入法时可选的方案及其顺序；默认的 rime-emoji recipe 也会按此列表逐个生成。
      '';
    };

    patch = lib.mkOption {
      type = yaml.type;
      example = {
        "menu/page_size" = 9;
        "switcher/hotkeys" = [ "F4" ];
      };
      description = ''
        Rime 补靪（patch），会被写入 default.custom.yaml 的 patch 节点。

        键为 `a/b/c` 形式的节点路径，遵循 Rime 的 `/+`（合并）与 `/=`（替换）操作符语法；也可用 `patchUtils.mkPatch` 简化书写。
      '';
      default = { };
    };

    customize = lib.mkOption {
      type = lib.types.attrsOf yaml.type;
      example = {
        symbols = {
          "punctuator/half_shape/#/=".commit = "#";
        };
      };
      description = ''
        按文件自定义 Rime 配置：键为文件名（不含 `.custom.yaml` 后缀），值为写入该文件的 patch 内容。

        例如 `customize.symbols = { ... }` 会生成 symbols.custom.yaml。
      '';
      default = { };
    };
  };

  config = lib.mkIf config.plum-nix.enable {
    home.file = {
      "${rime-dir}" = {
        source = config-package;
        recursive = true;
      };
      "${rime-dir}/default.custom.yaml".source = yaml.generate "default.custom.yaml" {
        patch.__patch = [
          "plum_nix"
          "user_patch"
        ];
        plum_nix = {
          schema_list = map (x: { schema = x; }) config.plum-nix.schemas;
        };
        user_patch = config.plum-nix.patch;
      };
    };
  };
}
