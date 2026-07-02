{ config, pkgs, ... }:

{
  home.stateVersion = "25.11";
  home.username = "test";
  home.homeDirectory = "/tmp/test";

  plum-nix.enable = true;
  plum-nix.type = "fcitx5";
  plum-nix.customize.luna_pinyin = {
    "test" = 1;
  };
}
