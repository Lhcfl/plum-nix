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