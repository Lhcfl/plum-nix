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
  ...
}:
let
  yaml = pkgs.formats.yaml { };

  getConfigInputMethod = lib.attrsets.attrByPath [ "i18n" "inputMethod" "type" ] null;

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
        export sources="$sources ${recipeStr}"
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

      ${copySources}
      ${copyRecipes}

      export plum_dir=$(pwd)
      export rime_dir=$out
      export no_update=1

      mkdir -p $out
      ./rime-install $sources

      runHook postBuild
    '';

    installPhase = ''
      runHook preInstall
      runHook postInstall
    '';
  };

  source =
    src:
    (lib.pipe src [
      builtins.readDir
      builtins.attrNames
      (map (name: {
        name = "${rime-dir}/${name}";
        value.source = "${src}/${name}";
      }))
      builtins.listToAttrs
    ]);

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
      description = "Rime 配置源列表。 https://github.com/rime/plum";
    };

    recipes = lib.mkOption {
      type = lib.types.listOf (
        lib.types.submodule {
          options = {
            src = lib.mkOption { type = lib.types.path; };
            recipe = lib.mkOption { type = lib.types.listOf lib.types.str; };
          };
        }
      );

      defaultText = ''
        默认启用 rime-emoji 的 recipe，recipe 会根据 config.plum-nix.schemas 生成，内容如下：
        {
          src = rime-emoji;
          recipe = map (schema: "customize:schema=$${schema}") config.plum-nix.schemas;
        }
      '';

      description = "Rime 配置 recipe 列表。 https://github.com/rime/home/wiki/Recipes";
    };

    type = lib.mkOption {
      type = lib.types.enum availableTypes;
      description = "你是使用的什麼方式啟用 rime 的輸入法框架？";
      defaultText = ''
        config.i18n.inputMethod.type or config.osConfig.i18n.inputMethod.type
      '';
    };

    schemas = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [
        "luna_pinyin"
        "luna_pinyin_fluency"
        "luna_pinyin_simp"
        "luna_pinyin_tw"
      ];
      description = "啟用的 Rime schema 名稱列表";
    };

    patch = lib.mkOption {
      type = yaml.type;
      description = "Rime 補靪檔，會被寫入到 default.custom.yaml 中";
      default = { };
    };
  };

  config = lib.mkIf config.plum-nix.enable {
    plum-nix.recipes = lib.mkDefault [
      {
        src = rime-emoji;
        recipe = map (schema: "customize:schema=${schema}") config.plum-nix.schemas;
      }
    ];

    # 不知为何它会引起无限循环
    # plum-nix.type = lib.mkDefault (
    #   lib.findFirst (x: getConfigInputMethod x != null) null [
    #     config
    #     osConfig
    #   ]
    # );

    home.file = lib.mkMerge [
      (source config-package)

      {
        "${rime-dir}/default.custom.yaml".source = yaml.generate "default.custom.yaml" {
          __patch = [
            "base_settings"
            "user_patch"
          ];
          base_settings = {
            schema_list = config.plum-nix.schemas;
          };
          user_patch = config.plum-nix.patch;
        };
      }
    ];
  };
}
