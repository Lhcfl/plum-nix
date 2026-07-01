# plum-nix

基于 [plum](https://github.com/rime/plum) 提供 Rime 输入法配置。

## Features

这是一个 plum 的 wrapper，允许通过 nix 风格的声明式配置 Rime 输入法。

## Install

使用 flake 安装：

```nix
{
  description = "your description";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";

    plum-nix.url = "github:Lhcfl/plum-nix";
    plum-nix.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs =
    {
      self,
      nixpkgs,
      plum-nix,
      home-manager,
      ...
    }:
    {
      nixosConfigurations = {
        your-hostname = nixpkgs.lib.nixosSystem {
          modules = [
            home-manager.nixosModules.home-manager
            (_: {
              home-manager.users.your-username = {
                imports = [
                  plum-nix.homeModules.default
                ];

                plum-nix.enable = true;
                # Rime 配置文件的存放位置，支持 fcitx5、ibus、fcitx
                plum-nix.type = "fcitx5";
                # 启用的 Rime 输入法方案
                plum-nix.schemas = [
                  "luna_pinyin"
                  "luna_pinyin_simp"
                  "luna_pinyin_tw"
                ];
              };
            })
          ];
        };
      };
    };
}

```

## Example

这是我自己的配置文件，供参考

```nix
_: {
  plum-nix = {
    enable = true;
    type = "fcitx5";

    # 会生成 default.custom.yaml
    patch = {
      "switcher/hotkeys" = [ "F4" ]; # 用 F4 切换
      "menu/page_side" = 9; # 一页写下 9 条

      # 让 key_binder/bindings 变为下面三个的 merge
      "key_binder/bindings".__patch = [
        "key_bindings:/move_by_word_with_tab"
        "key_bindings:/paging_with_brackets"
        "key_bindings:/numbered_mode_switch"
      ];
    };

    # 会生成 symbols.custom.yaml
    customize.symbols.patch = {
      "punctuator/half_shape/#/=".commit = "#";
    };
  };
}
```

生成的 default.custom.yaml 如下：

```yml
patch:
  __patch:
  - plum_nix
  - user_patch
plum_nix:
  schema_list:
  - schema: luna_pinyin
  - schema: luna_pinyin_fluency
  - schema: luna_pinyin_simp
  - schema: luna_pinyin_tw
user_patch:
  key_binder/bindings:
    __patch:
    - key_bindings:/move_by_word_with_tab
    - key_bindings:/paging_with_brackets
    - key_bindings:/numbered_mode_switch
  menu/page_side: 9
  switcher/hotkeys:
  - F4
```

生成的 symbols.custom.yaml 如下

```yml
patch:
  punctuator/half_shape/#/=:
    commit: '#'
```

## Limitations and Todo

- [ ] 识别和合并重复文件

  当前无法合并 .yaml 文件，哪怕 Rime ~~用很逆天的方式~~支持了合并 yaml