# Nix Rime Configuration

提供 Rime 输入法配置。

## TODO

- [] support recipes
- [] support multi `opencc` files

## Install

使用 flake 安装：

```nix
{
  description = "your description";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    rime-conf.url = "github:Lhcfl/nix-rime-conf";
    rime-conf.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs =
    inputs@{ self, nixpkgs, rime-conf, ... }: {
      nixosConfigurations = {
        your-hostname = nixpkgs.lib.nixosSystem {
          modules = [
            home-manager.nixosModules.home-manager
          ];

          home-manager.users.your-username = {
            imports = [
              rime-conf.homeModules.default
            ];

            rime-config.enable = true;
            rime-config.type = "fcitx5";
            rime-config.schemas = [
              "luna_pinyin"
              "luna_pinyin_simp"
              "luna_pinyin_tw"
            ];
          }
        };
      };
    };
}
```